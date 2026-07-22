# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Common
variable "prefix" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

# NLB
variable "internal" {
  type        = bool
  description = "true = internal NLB, false = internet-facing."
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the target groups."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the NLB."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups to attach to the NLB."
  default     = []
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for TLS listener."
  default     = null
}

variable "ssl_policy" {
  type        = string
  description = "TLS policy for NLB TLS listener."
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "deregistration_delay" {
  type        = number
  description = "Deregistration delay in seconds."
  default     = 60
}

variable "health_check_protocol" {
  type        = string
  description = "Health check protocol."
  default     = "TCP"
}

variable "health_check_path" {
  type        = string
  description = "Health check path for HTTP/HTTPS checks."
  default     = "/"
}

variable "health_check_port" {
  type        = string
  description = "Health check port; use 'traffic-port' or a number as string."
  default     = "traffic-port"
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection on NLB."
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  type    = bool
  default = true
}

# Generic target settings
variable "target_type" {
  type        = string
  description = "Target type for the NLB target group. Supported: instance, alb"
  default     = "instance"

  validation {
    condition     = contains(["instance", "alb"], var.target_type)
    error_message = "target_type must be either instance or alb."
  }
}

variable "target_port" {
  type        = number
  description = "Port that the target group forwards to."
  default     = 80
}

variable "listener_port" {
  type        = number
  description = "NLB listener port."
  default     = 443
}

variable "listener_protocol" {
  type        = string
  description = "Listener protocol. Supported: TCP, TLS"
  default     = "TLS"

  validation {
    condition     = contains(["TCP", "TLS"], var.listener_protocol)
    error_message = "listener_protocol must be TCP or TLS."
  }
}

variable "instance_ids" {
  type        = list(string)
  description = "EC2 instance IDs to register as targets when target_type=instance."
  default     = []
}

variable "alb_arn" {
  type        = string
  description = "ALB ARN to register as target when target_type=alb."
  default     = null
}

variable "create_ssh_listener" {
  type        = bool
  description = "Whether to create an SSH listener and target group."
  default     = false
}

variable "ssh_instance_ids" {
  type        = list(string)
  description = "EC2 instance IDs for the SSH target group."
  default     = []
}

# S3
variable "enable_access_logs" {
  type        = bool
  description = "Enable NLB access logs to S3."
  default     = true
}

variable "access_logs_bucket" {
  type        = string
  description = "Existing S3 bucket name for NLB access logs."
  default     = ""
}
