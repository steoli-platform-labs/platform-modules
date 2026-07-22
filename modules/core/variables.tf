# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Common
variable "prefix" {
  type        = string
  description = "Added to the name of all resources created"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "create_operational_baseline" {
  description = "Create the legacy operational baseline resources such as app security groups, instance profile and key pair."
  type        = bool
  default     = true
}


# VPC
variable "create_vpc" {
  description = "Create a VPC instead of looking up or using an existing VPC."
  type        = bool
  default     = false
}

variable "vpc_name" {
  description = "Name used when creating the VPC and related resources. Defaults to prefix when unset."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "Explicit VPC ID. If set, this is used instead of vpc_name_filter."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC when create_vpc is true."
  type        = string
  default     = "10.100.0.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "secondary_cidr_blocks" {
  description = "Additional IPv4 CIDR blocks associated with the VPC when create_vpc is true. Use planned, non-overlapping ranges for high-IP consumers such as EKS."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.secondary_cidr_blocks : can(cidrnetmask(cidr))])
    error_message = "secondary_cidr_blocks must contain valid IPv4 CIDR blocks."
  }
}

variable "availability_zones" {
  description = "Availability Zones used by the public and private subnets when create_vpc is true."
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets when create_vpc is true."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets when create_vpc is true."
  type        = list(string)
  default     = []
}

variable "enable_single_nat_gateway" {
  description = "Use one shared NAT Gateway when create_vpc is true. Set false to create one NAT Gateway per Availability Zone."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Optional EKS cluster name used for Kubernetes subnet discovery tags."
  type        = string
  default     = null
}

variable "vpc_name_filter" {
  description = "VPC Name tag filter used when vpc_id is not set."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "Explicit public subnet IDs. If set, these are used instead of public_subnet_name_filter."
  type        = list(string)
  default     = []
}

variable "public_subnet_name_filter" {
  description = "Public subnet Name tag filter used when public_subnet_ids is empty."
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Explicit private subnet IDs. If set, these are used instead of private_subnet_name_filter."
  type        = list(string)
  default     = []
}

variable "private_subnet_name_filter" {
  description = "Private subnet Name tag filter used when private_subnet_ids is empty."
  type        = string
  default     = null
}

variable "private_route_table_ids" {
  description = "Explicit private route table IDs. If set, these are used instead of private_route_table_name_filter."
  type        = list(string)
  default     = []
}

variable "private_route_table_name_filter" {
  description = "Private route table Name tag filter used when private_route_table_ids is empty."
  type        = string
  default     = null
}


# VPC endpoint
variable "create_ssm_vpc_endpoint" {
  description = "Create an SSM Interface VPC endpoint so SSM traffic stays within the AWS network and can avoid NAT gateway need."
  type        = bool
  default     = false
}

variable "create_s3_vpc_endpoint" {
  description = "Create an S3 gateway VPC endpoint so S3 traffic stays within the AWS network and can avoid NAT gateway charges."
  type        = bool
  default     = false
}

variable "s3_vpc_endpoint_route_table_ids" {
  description = "Optional explicit route table IDs for the S3 VPC endpoint. If empty, private_route_table_ids are used."
  type        = list(string)
  default     = []
}

variable "s3_vpc_endpoint_policy" {
  description = "Optional custom policy JSON for the S3 VPC endpoint. If null, the default full-access endpoint policy is used."
  type        = string
  default     = null
}


# SG
variable "zabbix_cidr_blocks" {
  type    = list(string)
  default = ["49.13.250.58/32", "10.147.0.70/32"]
}

variable "lb_ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach load balancers."
  default     = ["0.0.0.0/0"]
}


# EC2
variable "ssh_public_key" {
  description = "Public key used for the optional operational EC2 key pair. Required when create_operational_baseline is true."
  type        = string
  default     = null
}


# S3
variable "create_aws_ssm_bucket" {
  type    = bool
  default = false
}

variable "create_alb_access_logs_bucket" {
  type        = bool
  description = "Create S3 bucket for ALB access logs."
  default     = false
}

variable "create_nlb_access_logs_bucket" {
  type        = bool
  description = "Create S3 bucket for NLB access logs."
  default     = false
}

variable "enable_access_logs" {
  type        = bool
  description = "Enable ALB access logs to S3."
  default     = true
}

variable "alb_access_logs_bucket" {
  type        = string
  description = "Optional existing S3 bucket name for ALB access logs. If empty and enable_access_logs=true, the module will create one."
  default     = ""
}

variable "nlb_access_logs_bucket" {
  type        = string
  description = "Optional existing S3 bucket name for NLB access logs. If empty and enable_access_logs=true, the module will create one."
  default     = ""
}


# Instance Scheduler
variable "create_instance_scheduler" {
  type    = bool
  default = false
}

variable "start_disabled" {
  type    = bool
  default = false
}

variable "runtime" {
  default = "python3.12"
}

variable "lambda_timeout" {
  type    = number
  default = 600
}

variable "tag" {
  default = "Scheduler:Enabled"
}

variable "start_expression" {
  default = "cron(0 7 ? * MON-FRI *)"
}

variable "stop_expression" {
  default = "cron(0 19 ? * MON-FRI *)"
}

variable "timezone" {
  default = "Europe/Stockholm"
}

variable "dryrun" {
  default = "false"
}


# VPN
variable "vpn_connections" {
  default = {}
}

variable "vpn_static_routes_only" {
  type    = bool
  default = true
}

variable "vpn_amazon_side_asn" {
  type    = number
  default = 64512
}

variable "vpn_customer_side_asn" {
  type    = number
  default = 65000
}

variable "vpn_dh_group_number" {
  type    = string
  default = "14"
}

variable "vpn_encryption_algorithm" {
  type    = string
  default = "AES256"
}

variable "vpn_integrity_algorithm" {
  type    = string
  default = "SHA2-256"
}

variable "vpn_phase1_lifetime_seconds" {
  type    = number
  default = 28800
}

variable "vpn_phase2_lifetime_seconds" {
  type    = number
  default = 3600
}

variable "vpn_rekey_margin_time_seconds" {
  type    = number
  default = 540
}

variable "vpn_ike_version" {
  type    = string
  default = "ikev2"
}

variable "vpn_startup_action" {
  type    = string
  default = "add"
}

variable "vpn_dpd_timeout_action" {
  type    = string
  default = "clear"
}

variable "vpn_dpd_timeout_seconds" {
  type    = number
  default = 30
}

variable "vpn_preshared_key" {
  type    = string
  default = ""
}

variable "vpn_log_retention_in_days" {
  type    = number
  default = 3
}


# AWS Backup
variable "create_backup_vault" {
  type        = bool
  description = "Controls if Backup Vault are to be created"
  default     = false
}

variable "create_backup_vault_policy" {
  type    = bool
  default = false
}

variable "create_backup_copy" {
  type        = bool
  description = "Optional override to backup_plan_rules to be able to disable copy"
  default     = false
}

variable "backup_expire_days" {
  type        = number
  description = "Optional override to backup_plan_rules to be able to set backup_expire_days"
  default     = 0
}

variable "backup_copy_region" {
  default = "eu-west-1"
}

variable "backup_selection_tag" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "Backup"
    value = "true"
  }
}

variable "backup_plan_rules" {
  type = list(object({
    name              = string
    schedule          = string
    start_window      = number
    completion_window = number
    expire_days       = number
    copy_expire_days  = number
  }))
  default = [
    {
      name              = "RuleForDailyBackups",
      schedule          = "cron(0 1 ? * * *)"
      start_window      = 60
      completion_window = 1200
      expire_days       = 31
      copy_expire_days  = 7
    }
  ]
}


# SNS
variable "create_backup_sns_topic" {
  type    = bool
  default = false
}

variable "sns_protocol" {
  type    = string
  default = "https"
}

variable "sns_subscriber" {
  type    = string
  default = ""
}

variable "sns_subscriber_auto_confirms" {
  type        = bool
  description = "True if subscriber can auto confirm like for example Opsgenie"
  default     = true
}
