# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
variable "prefix" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the DB subnet group."
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups allowed to connect to Postgres."
}

variable "username" {
  type        = string
  description = "Master username."
  default     = "postgres"
}

variable "password" {
  type        = string
  description = "Optional master password override. If empty, module will generate one."
  sensitive   = true
  default     = ""
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB."
  default     = 50
}

variable "max_allocated_storage" {
  type        = number
  description = "Max allocated storage in GB for autoscaling. Set to 0 to disable."
  default     = 0
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ."
  default     = false
}

variable "engine_version" {
  type        = string
  description = "Postgres engine version."
  default     = "16"
}

variable "storage_type" {
  type        = string
  description = "Storage type (gp3 recommended)."
  default     = "gp3"
}

variable "apply_immediately" {
  type        = bool
  description = "Apply changes immediately (useful for labs)."
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on delete (OK for lab, not recommended for prod)."
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Protect RDS from being deleted."
  default     = true
}

variable "backup_retention_period" {
  type        = number
  description = "Days to retain backups. 0 disables."
  default     = 31
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "allow_major_version_upgrade" {
  type    = bool
  default = false
}

variable "backup_window" {
  default = "22:00-23:59"
}

variable "maintenance_window" {
  default = "Sun:20:00-Sun:21:59"
}
