# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
variable "prefix" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "buckets" {
  description = <<EOT
Buckets to create.

You can pass either:
- list(string): bucket suffixes; module will build final name as: <prefix>-<stack_name>-<suffix>
- map(object): for per-bucket settings (recommended)
EOT
  type        = any
}

variable "common_tags" {
  description = "Tags applied to all buckets"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "If true, allows Terraform to delete non-empty buckets"
  type        = bool
  default     = false
}

variable "default_versioning" {
  description = "Default versioning behavior if not set per bucket"
  type        = bool
  default     = true
}

variable "default_lifecycle_rules" {
  description = "Lifecycle rules applied to all buckets unless overridden per-bucket."
  type        = list(any)
  default = [
    {
      id                           = "default-cleanup"
      enabled                      = true
      abort_multipart_days         = 7
      expired_object_delete_marker = true
      noncurrent_expiration_days   = 30
    }
  ]
}
