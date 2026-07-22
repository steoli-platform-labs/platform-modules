variable "name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs granted Kubernetes cluster admin access through EKS access entries."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
