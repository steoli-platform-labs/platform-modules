# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# VPN
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
locals {
  create_vpn = length(keys(var.vpn_connections)) > 0

  # Expanded matrix of route-table routes to create in the VPC route tables
  vpn_routes = distinct(flatten([
    for i in range(length(local.private_route_table_ids)) : [
      for k, v in var.vpn_connections : [
        for cidr in v.customer_subnets : {
          dest           = k
          dest_cidr      = cidr
          route_table_id = i
        }
      ]
    ]
  ]))

  # Expanded matrix of static routes to register on each VPN connection
  vpn_connection_routes = {
    for item in flatten([
      for connection_name, connection in var.vpn_connections : [
        for cidr in connection.customer_subnets : {
          key                    = "${connection_name}-${replace(cidr, "/", "-")}"
          connection_name        = connection_name
          destination_cidr_block = cidr
        }
      ]
    ]) : item.key => item
  }
}

output "vpn_routes" {
  value = local.vpn_routes
}

# Customer gateway
resource "aws_customer_gateway" "this" {
  for_each = var.vpn_connections

  bgp_asn    = lookup(each.value, "customer_gateway_bgp_asn", var.vpn_customer_side_asn)
  ip_address = each.value.customer_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-${each.key}"
  })
}

# VPN gateway (VGW) attached to the existing VPC
resource "aws_vpn_gateway" "this" {
  count = local.create_vpn ? 1 : 0

  amazon_side_asn = var.vpn_amazon_side_asn

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-vgw"
  })
}

resource "aws_vpn_gateway_attachment" "this" {
  count = local.create_vpn ? 1 : 0

  vpc_id         = local.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this[0].id
}

# VPN connection
resource "aws_vpn_connection" "this" {
  for_each = var.vpn_connections

  vpn_gateway_id      = aws_vpn_gateway.this[0].id
  customer_gateway_id = aws_customer_gateway.this[each.key].id
  type                = "ipsec.1"

  static_routes_only = lookup(each.value, "static_routes_only", var.vpn_static_routes_only)

  tunnel1_phase1_dh_group_numbers      = [lookup(each.value, "dh_group_number", var.vpn_dh_group_number)]
  tunnel1_phase1_encryption_algorithms = [lookup(each.value, "encryption_algorithm", var.vpn_encryption_algorithm)]
  tunnel1_phase1_integrity_algorithms  = [lookup(each.value, "integrity_algorithm", var.vpn_integrity_algorithm)]
  tunnel1_phase1_lifetime_seconds      = lookup(each.value, "phase1_lifetime_seconds", var.vpn_phase1_lifetime_seconds)
  tunnel1_phase2_dh_group_numbers      = [lookup(each.value, "dh_group_number", var.vpn_dh_group_number)]
  tunnel1_phase2_encryption_algorithms = [lookup(each.value, "encryption_algorithm", var.vpn_encryption_algorithm)]
  tunnel1_phase2_integrity_algorithms  = [lookup(each.value, "integrity_algorithm", var.vpn_integrity_algorithm)]
  tunnel1_phase2_lifetime_seconds      = lookup(each.value, "phase2_lifetime_seconds", var.vpn_phase2_lifetime_seconds)
  tunnel1_dpd_timeout_action           = lookup(each.value, "dpd_timeout_action", var.vpn_dpd_timeout_action)
  tunnel1_dpd_timeout_seconds          = lookup(each.value, "dpd_timeout_seconds", var.vpn_dpd_timeout_seconds)
  tunnel1_ike_versions                 = [lookup(each.value, "ike_version", var.vpn_ike_version)]
  tunnel1_preshared_key                = lookup(each.value, "preshared_key", var.vpn_preshared_key)
  tunnel1_rekey_margin_time_seconds    = lookup(each.value, "rekey_margin_time_seconds", var.vpn_rekey_margin_time_seconds)
  tunnel1_startup_action               = lookup(each.value, "startup_action", var.vpn_startup_action)

  tunnel1_log_options {
    cloudwatch_log_options {
      log_enabled       = true
      log_group_arn     = aws_cloudwatch_log_group.vpn[each.key].arn
      log_output_format = "text"
    }
  }

  tunnel2_phase1_dh_group_numbers      = [lookup(each.value, "dh_group_number", var.vpn_dh_group_number)]
  tunnel2_phase1_encryption_algorithms = [lookup(each.value, "encryption_algorithm", var.vpn_encryption_algorithm)]
  tunnel2_phase1_integrity_algorithms  = [lookup(each.value, "integrity_algorithm", var.vpn_integrity_algorithm)]
  tunnel2_phase1_lifetime_seconds      = lookup(each.value, "phase1_lifetime_seconds", var.vpn_phase1_lifetime_seconds)
  tunnel2_phase2_dh_group_numbers      = [lookup(each.value, "dh_group_number", var.vpn_dh_group_number)]
  tunnel2_phase2_encryption_algorithms = [lookup(each.value, "encryption_algorithm", var.vpn_encryption_algorithm)]
  tunnel2_phase2_integrity_algorithms  = [lookup(each.value, "integrity_algorithm", var.vpn_integrity_algorithm)]
  tunnel2_phase2_lifetime_seconds      = lookup(each.value, "phase2_lifetime_seconds", var.vpn_phase2_lifetime_seconds)
  tunnel2_dpd_timeout_action           = lookup(each.value, "dpd_timeout_action", var.vpn_dpd_timeout_action)
  tunnel2_dpd_timeout_seconds          = lookup(each.value, "dpd_timeout_seconds", var.vpn_dpd_timeout_seconds)
  tunnel2_ike_versions                 = [lookup(each.value, "ike_version", var.vpn_ike_version)]
  tunnel2_preshared_key                = lookup(each.value, "preshared_key", var.vpn_preshared_key)
  tunnel2_rekey_margin_time_seconds    = lookup(each.value, "rekey_margin_time_seconds", var.vpn_rekey_margin_time_seconds)
  tunnel2_startup_action               = lookup(each.value, "startup_action", var.vpn_startup_action)

  tunnel2_log_options {
    cloudwatch_log_options {
      log_enabled       = true
      log_group_arn     = aws_cloudwatch_log_group.vpn[each.key].arn
      log_output_format = "text"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-${each.key}"
  })

  depends_on = [aws_vpn_gateway_attachment.this]
}

# Static routes on the VPN connection itself
resource "aws_vpn_connection_route" "this" {
  for_each = local.create_vpn ? local.vpn_connection_routes : {}

  vpn_connection_id      = aws_vpn_connection.this[each.value.connection_name].id
  destination_cidr_block = each.value.destination_cidr_block
}

# Routes in all discovered private route tables pointing at the VGW
resource "aws_route" "vpn" {
  for_each = local.create_vpn ? {
    for x in local.vpn_routes :
    "${x.dest}-${replace(x.dest_cidr, "/", "-")}-rt${x.route_table_id}" => x
  } : {}

  route_table_id         = element(local.private_route_table_ids, each.value.route_table_id)
  destination_cidr_block = each.value.dest_cidr
  gateway_id             = aws_vpn_gateway.this[0].id

  depends_on = [
    aws_vpn_connection.this,
    aws_vpn_connection_route.this
  ]
}
