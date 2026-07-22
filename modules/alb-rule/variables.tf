# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

variable "vpc_id" {
  type        = string
  description = "VPC id for the target group."
  default     = null
}

variable "listener_arn" {
  type        = string
  description = "ALB listener ARN (http or https)."
}

variable "priority" {
  type        = number
  description = "Unique listener rule priority on this listener."
}

variable "hostnames" {
  type        = list(string)
  description = "Host header values."
  default     = []
}

variable "path_patterns" {
  type        = list(string)
  description = "Path pattern values."
  default     = []
}

variable "instance_ids" {
  type        = list(string)
  description = "Instance IDs to attach to the target group."
  default     = []
}

variable "backend_port" {
  type        = number
  description = "Backend port on the instances."
  default     = 80
}

variable "backend_protocol" {
  type        = string
  description = "Protocol for the target group."
  default     = "HTTP"
}

variable "deregistration_delay" {
  type        = number
  description = "Deregistration delay in seconds."
  default     = 60
}

variable "health_check_path" {
  type        = string
  description = "Health check path."
  default     = "/"
}

variable "health_check_protocol" {
  type        = string
  description = "Health check protocol."
  default     = "HTTP"
}

variable "health_check_matcher" {
  type        = string
  description = "HTTP matcher codes."
  default     = "200-399"
}

variable "health_check_healthy_threshold" {
  type    = number
  default = 2
}

variable "health_check_unhealthy_threshold" {
  type    = number
  default = 2
}

variable "health_check_interval" {
  type    = number
  default = 30
}

variable "health_check_timeout" {
  type    = number
  default = 5
}

variable "fixed_response" {
  type = object({
    content_type = string
    message_body = string
    status_code  = string
  })
  default = null
}

variable "redirect" {
  type = object({
    host        = string
    port        = string
    protocol    = string
    path        = string
    query       = string
    status_code = string
  })
  default = null
}