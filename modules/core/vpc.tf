# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

locals {
  vpc_name                    = coalesce(var.vpc_name, var.prefix)
  use_vpc_id                  = var.vpc_id != null && var.vpc_id != ""
  use_public_subnet_ids       = length(var.public_subnet_ids) > 0
  use_private_subnet_ids      = length(var.private_subnet_ids) > 0
  use_private_route_table_ids = length(var.private_route_table_ids) > 0

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  cluster_tags = var.cluster_name == null ? {} : {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_names = [
    for index, _ in var.public_subnet_cidrs : "${var.prefix}-public-${element(var.availability_zones, index)}"
  ]

  private_subnet_names = [
    for index, _ in var.private_subnet_cidrs : index < length(var.availability_zones)
    ? "${var.prefix}-platform-private-${element(var.availability_zones, index)}"
    : "${var.prefix}-eks-private-${element(var.availability_zones, index - length(var.availability_zones))}"
  ]
}

module "vpc" {
  count = var.create_vpc ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = local.vpc_name
  cidr = var.vpc_cidr

  secondary_cidr_blocks = var.secondary_cidr_blocks

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  public_subnet_names  = local.public_subnet_names
  private_subnet_names = local.private_subnet_names

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw = true

  enable_nat_gateway     = true
  single_nat_gateway     = var.enable_single_nat_gateway
  one_nat_gateway_per_az = !var.enable_single_nat_gateway

  map_public_ip_on_launch = false

  public_subnet_tags  = local.public_subnet_tags
  private_subnet_tags = local.private_subnet_tags

  tags = merge(var.common_tags, local.cluster_tags)
}

# VPC
# Lookup VPC by name only when vpc_id is not provided
data "aws_vpc" "by_name" {
  count = var.create_vpc || local.use_vpc_id || var.vpc_name_filter == null || var.vpc_name_filter == "" ? 0 : 1

  filter {
    name   = "tag:Name"
    values = [var.vpc_name_filter]
  }
}

locals {
  vpc_id = var.create_vpc ? module.vpc[0].vpc_id : (local.use_vpc_id ? var.vpc_id : (length(data.aws_vpc.by_name) > 0 ? data.aws_vpc.by_name[0].id : null))
}

# Always read the selected VPC so the rest of the module can use its attributes
data "aws_vpc" "this" {
  count = var.create_operational_baseline || var.create_ssm_vpc_endpoint ? 1 : 0

  id = local.vpc_id
}

# Public subnets
data "aws_subnets" "public" {
  count = (!local.use_public_subnet_ids && var.public_subnet_name_filter != null && var.public_subnet_name_filter != "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [var.public_subnet_name_filter]
  }
}

# Private subnets
data "aws_subnets" "private" {
  count = (!local.use_private_subnet_ids && var.private_subnet_name_filter != null && var.private_subnet_name_filter != "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [var.private_subnet_name_filter]
  }
}

# Private route tables
data "aws_route_tables" "private" {
  count = (!local.use_private_route_table_ids && var.private_route_table_name_filter != null && var.private_route_table_name_filter != "") ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = [var.private_route_table_name_filter]
  }
}

locals {
  public_subnet_ids = local.use_public_subnet_ids ? var.public_subnet_ids : (
    var.create_vpc ? module.vpc[0].public_subnets : (length(data.aws_subnets.public) > 0 ? data.aws_subnets.public[0].ids : [])
  )

  private_subnet_ids = local.use_private_subnet_ids ? var.private_subnet_ids : (
    var.create_vpc ? module.vpc[0].private_subnets : (length(data.aws_subnets.private) > 0 ? data.aws_subnets.private[0].ids : [])
  )

  private_route_table_ids = local.use_private_route_table_ids ? var.private_route_table_ids : (
    var.create_vpc ? module.vpc[0].private_route_table_ids : (length(data.aws_route_tables.private) > 0 ? data.aws_route_tables.private[0].ids : [])
  )
}


# VPC endpoints
locals {
  s3_vpc_endpoint_route_table_ids = length(var.s3_vpc_endpoint_route_table_ids) > 0 ? var.s3_vpc_endpoint_route_table_ids : local.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3" {
  count = var.create_s3_vpc_endpoint ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.s3_vpc_endpoint_route_table_ids
  policy            = var.s3_vpc_endpoint_policy

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-s3-endpoint"
  })
}

locals {
  ssm_endpoints = toset([
    "ssm",
    "ssmmessages",
    "ec2messages"
  ])

  ssm_endpoints_enabled = var.create_ssm_vpc_endpoint ? local.ssm_endpoints : toset([])
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = var.create_operational_baseline ? local.ssm_endpoints_enabled : toset([])

  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_vpce[0].id]
  private_dns_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.prefix}-${each.key}-vpce"
  })
}
