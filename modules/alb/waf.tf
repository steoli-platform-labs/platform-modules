# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# WAF
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# WAF
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

locals {
  create_default_waf = var.waf_enabled && !var.custom_wafv2_web_acl_enabled
}

# Blocklist
resource "aws_wafv2_ip_set" "blocklist" {
  count = local.create_default_waf && length(var.waf_ip_blocklist) > 0 ? 1 : 0

  name               = "${var.prefix}-blocklist"
  description        = "Blocked IP addresses"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.waf_ip_blocklist

  tags = var.common_tags
}

# Default Web ACL
resource "aws_wafv2_web_acl" "this" {
  count = local.create_default_waf ? 1 : 0

  name        = "${var.prefix}-waf"
  description = "Web ACL using AWS Managed Rules"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.prefix}-waf-metric"
    sampled_requests_enabled   = true
  }

  # AWS managed rules
  dynamic "rule" {
    for_each = var.waf_managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"

          dynamic "rule_action_override" {
            for_each = rule.value.excluded_rules
            content {
              name = rule_action_override.value
              action_to_use {
                count {}
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  # IP blocklist
  dynamic "rule" {
    for_each = length(var.waf_ip_blocklist) > 0 ? [1] : []

    content {
      name     = "BlockList"
      priority = var.waf_ip_blocklist_rule_priority

      action {
        block {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.blocklist[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BlockList"
        sampled_requests_enabled   = true
      }
    }
  }

  # URI blocklist
  dynamic "rule" {
    for_each = length(var.waf_uri_blocklist) > 0 ? [1] : []

    content {
      name     = "URI-BlockList"
      priority = var.waf_uri_blocklist_rule_priority

      action {
        block {}
      }

      statement {
        dynamic "or_statement" {
          for_each = length(var.waf_uri_blocklist) > 1 ? [1] : []

          content {
            dynamic "statement" {
              for_each = toset(var.waf_uri_blocklist)

              content {
                byte_match_statement {
                  field_to_match {
                    uri_path {}
                  }

                  positional_constraint = "EXACTLY"
                  search_string         = statement.value

                  text_transformation {
                    priority = 0
                    type     = "NONE"
                  }
                }
              }
            }
          }
        }

        dynamic "byte_match_statement" {
          for_each = length(var.waf_uri_blocklist) == 1 ? [1] : []

          content {
            field_to_match {
              uri_path {}
            }

            positional_constraint = "EXACTLY"
            search_string         = var.waf_uri_blocklist[0]

            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "DynamicBlockURIs"
        sampled_requests_enabled   = true
      }
    }
  }

  tags = var.common_tags
}

# Existing custom Web ACL
data "aws_wafv2_web_acl" "custom" {
  count = var.waf_enabled && var.custom_wafv2_web_acl_enabled ? 1 : 0

  name  = var.custom_wafv2_web_acl_name
  scope = "REGIONAL"
}

# Default Web ACL association - internal
resource "aws_wafv2_web_acl_association" "internal_default" {
  count = var.create_internal_alb && local.create_default_waf ? 1 : 0

  resource_arn = aws_lb.internal[0].arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}

# Default Web ACL association - external
resource "aws_wafv2_web_acl_association" "external_default" {
  count = var.create_external_alb && local.create_default_waf ? 1 : 0

  resource_arn = aws_lb.external[0].arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}

# Custom Web ACL association - internal
resource "aws_wafv2_web_acl_association" "internal_custom" {
  count = var.create_internal_alb && var.waf_enabled && var.custom_wafv2_web_acl_enabled ? 1 : 0

  resource_arn = aws_lb.internal[0].arn
  web_acl_arn  = data.aws_wafv2_web_acl.custom[0].arn
}

# Custom Web ACL association - external
resource "aws_wafv2_web_acl_association" "external_custom" {
  count = var.create_external_alb && var.waf_enabled && var.custom_wafv2_web_acl_enabled ? 1 : 0

  resource_arn = aws_lb.external[0].arn
  web_acl_arn  = data.aws_wafv2_web_acl.custom[0].arn
}