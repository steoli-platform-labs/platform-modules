# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
variable "prefix" {
  type = string
}

variable "stack_name" {
  type = string
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create."
  default     = 1
}

variable "ami_id" {
  type        = string
  description = "AMI ID to use."
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs. Instances will be spread round-robin."

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet id."
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs to attach."
}

variable "iam_instance_profile" {
  type        = string
  description = "Instance profile name to attach."
  default     = null
}

variable "root_volume_size" {
  type    = number
  default = 50
}

variable "data_volume_size" {
  type    = number
  default = 100
}

variable "ebs_mount_vars" {
  type = map(any)
  default = {
    mount_point = "/data"
    vg_name     = "data"
    lv_name     = "data_volume"
  }
}

variable "additional_data_volumes" {
  description = "Optional extra EBS data volumes to create per instance."
  type = list(object({
    name        = string
    size        = number
    type        = optional(string, "gp3")
    encrypted   = optional(bool, true)
    device_name = string
  }))
  default = []

  validation {
    condition = alltrue([
      for v in var.additional_data_volumes :
      startswith(v.device_name, "/dev/sd")
    ])
    error_message = "Each additional_data_volumes.device_name must start with /dev/sd (for example /dev/sdg)."
  }
}

variable "efs_mount_point" {
  type    = string
  default = "/data/nfs"
}

variable "efs_mount_options" {
  type    = string
  default = "nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,noatime,_netdev"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "instance_tags" {
  description = "Extra tags applied only to the EC2 instance resource."
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "Extra tags applied only to EBS volumes (root + data + additional data)."
  type        = map(string)
  default     = {}
}

variable "ec2_disable_api_termination" {
  type    = bool
  default = true
}

variable "ec2_http_endpoint" {
  default = "enabled"

  validation {
    condition     = contains(["enabled", "disabled"], var.ec2_http_endpoint)
    error_message = "Valid values for variable ec2_http_endpoint are: enabled or disabled"
  }
}

variable "ec2_http_tokens" {
  default = "required"

  validation {
    condition     = contains(["optional", "required"], var.ec2_http_tokens)
    error_message = "Valid values for variable ec2_http_tokens are: optional or required"
  }
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name to attach to instances (for SSH). Leave empty to not set a key."
  default     = ""
}
