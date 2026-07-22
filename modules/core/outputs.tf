# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Outputs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# VPC
output "vpc_id" {
  value = local.vpc_id
}

output "vpc_cidr_block" {
  value = var.create_vpc ? module.vpc[0].vpc_cidr_block : try(data.aws_vpc.this[0].cidr_block, null)
}

output "vpc_secondary_cidr_blocks" {
  value = var.create_vpc ? var.secondary_cidr_blocks : []
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "nat_gateway_ids" {
  value = var.create_vpc ? module.vpc[0].natgw_ids : []
}

output "internet_gateway_id" {
  value = var.create_vpc ? module.vpc[0].igw_id : null
}

output "public_route_table_ids" {
  value = var.create_vpc ? module.vpc[0].public_route_table_ids : []
}

output "private_route_table_ids" {
  value = local.private_route_table_ids
}

output "s3_vpc_endpoint_id" {
  value = try(aws_vpc_endpoint.s3[0].id, null)
}


# IAM
output "iam_instance_profile" {
  value = try(aws_iam_instance_profile.instance_profile[0].name, null)
}


# Security groups
output "sg_alb_id" {
  value = try(aws_security_group.alb[0].id, null)
}

output "sg_nlb_id" {
  value = try(aws_security_group.nlb[0].id, null)
}

output "sg_gitlab_id" {
  value = try(aws_security_group.gitlab[0].id, null)
}

output "sg_sonarqube_id" {
  value = try(aws_security_group.sonarqube[0].id, null)
}

output "sg_artifactory_id" {
  value = try(aws_security_group.artifactory[0].id, null)
}

output "sg_zabbix_id" {
  value = try(aws_security_group.zabbix[0].id, null)
}


# S3
output "aws_ssm_bucket" {
  value = var.create_aws_ssm_bucket ? try(aws_s3_bucket.aws-ssm[0].bucket, "") : ""
}

output "alb_access_logs_bucket" {
  value = var.create_alb_access_logs_bucket ? aws_s3_bucket.alb_logs[0].bucket : var.alb_access_logs_bucket
}

output "nlb_access_logs_bucket" {
  value = var.create_nlb_access_logs_bucket ? aws_s3_bucket.nlb_logs[0].bucket : var.nlb_access_logs_bucket
}


# EC2
output "ansible_key_name" {
  value = try(aws_key_pair.ansible[0].key_name, null)
}
