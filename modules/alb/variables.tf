# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
variable "prefix" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "create_internal_alb" {
  type    = bool
  default = false
}

variable "create_external_alb" {
  type    = bool
  default = false
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for internal ALB."
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for external ALB."
  default     = []
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID to attach to the ALB."
}

variable "certificate_arn" {
  type        = string
  description = "Default ACM certificate ARN for HTTPS listeners."
  default     = ""
}

variable "additional_certificate_arns" {
  type        = list(string)
  description = "Additional ACM certificate ARNs."
  default     = []
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "idle_timeout" {
  type    = number
  default = 300
}

variable "enable_deletion_protection" {
  type    = bool
  default = true
}

variable "enable_access_logs" {
  type    = bool
  default = true
}

variable "access_logs_bucket" {
  type        = string
  description = "Existing bucket for ALB access logs."
  default     = ""
}


# WAF
variable "waf_enabled" {
  type        = bool
  description = "Enable WAF association for the ALB."
  default     = false
}

variable "waf_ip_blocklist" {
  description = "Blocked IP addresses"
  type        = list(string)
  default     = []
}

variable "waf_uri_blocklist" {
  type    = list(string)
  default = []
}

variable "waf_ip_blocklist_rule_priority" {
  type    = number
  default = 10
}

variable "waf_uri_blocklist_rule_priority" {
  type    = number
  default = 11
}

variable "custom_wafv2_web_acl_enabled" {
  type    = bool
  default = false
}

variable "custom_wafv2_web_acl_name" {
  type    = string
  default = ""
}

variable "waf_managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    excluded_rules  = list(string)
  }))

  description = "List of managed WAF rules."
  default = [
    {
      name            = "AWSManagedRulesAmazonIpReputationList"
      priority        = 0
      override_action = "none"
      excluded_rules  = []
    },
    {
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      priority        = 1
      override_action = "none"
      excluded_rules  = []
    }
  ]
}
