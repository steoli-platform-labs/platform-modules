# Core Terraform Module

This module provisions shared AWS platform components. It can create a VPC, use an existing VPC, create the IAM foundation roles, and optionally create operational helpers such as security groups, VPC endpoints, backup, VPN, instance scheduling and log buckets.

## Features

- Optional VPC creation or VPC integration with lookup by ID or Name tag filters
- Optional secondary VPC CIDR blocks for high-IP consumers such as EKS
- Security groups for ALB/NLB, GitLab, SonarQube, Artifactory, Zabbix, and SSM interface endpoints
- IAM instance role/profile and additional policies for GitLab, backup, and scheduler
- SSH key pair creation for EC2 (`ansible` key)
- Optional S3 buckets for SSM artifacts and ALB/NLB access logs
- Optional S3 and SSM VPC endpoints
- Optional instance scheduler (Lambda + EventBridge)
- Optional AWS Backup + SNS notifications
- Optional site-to-site VPN resources and route programming

## Example Usage

```hcl
module "core" {
  source = "../modules/core"

  prefix         = "prod-platform"
  ssh_public_key = "ssh-rsa AAAAB3Nza..."

  vpc_id                  = "vpc-0123456789abcdef0"
  public_subnet_ids       = ["subnet-aaa", "subnet-bbb"]
  private_subnet_ids      = ["subnet-ccc", "subnet-ddd"]
  private_route_table_ids = ["rtb-111", "rtb-222"]

  create_ssm_vpc_endpoint       = true
  create_s3_vpc_endpoint        = true
  create_alb_access_logs_bucket = true
  create_nlb_access_logs_bucket = true
  create_instance_scheduler     = true
  create_backup_vault           = true
  create_backup_sns_topic       = true
  sns_subscriber                = "https://example.alert.endpoint"

  common_tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alb_access_logs_bucket"></a> [alb\_access\_logs\_bucket](#input\_alb\_access\_logs\_bucket) | Optional existing S3 bucket name for ALB access logs. If empty and enable\_access\_logs=true, the module will create one. | `string` | `""` | no |
| <a name="input_backup_copy_region"></a> [backup\_copy\_region](#input\_backup\_copy\_region) | n/a | `string` | `"eu-west-1"` | no |
| <a name="input_backup_expire_days"></a> [backup\_expire\_days](#input\_backup\_expire\_days) | Optional override to backup\_plan\_rules to be able to set backup\_expire\_days | `number` | `0` | no |
| <a name="input_backup_plan_rules"></a> [backup\_plan\_rules](#input\_backup\_plan\_rules) | n/a | <pre>list(object({<br/>    name              = string<br/>    schedule          = string<br/>    start_window      = number<br/>    completion_window = number<br/>    expire_days       = number<br/>    copy_expire_days  = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "completion_window": 1200,<br/>    "copy_expire_days": 7,<br/>    "expire_days": 31,<br/>    "name": "RuleForDailyBackups",<br/>    "schedule": "cron(0 1 ? * * *)",<br/>    "start_window": 60<br/>  }<br/>]</pre> | no |
| <a name="input_backup_selection_tag"></a> [backup\_selection\_tag](#input\_backup\_selection\_tag) | n/a | <pre>object({<br/>    key   = string<br/>    value = string<br/>  })</pre> | <pre>{<br/>  "key": "Backup",<br/>  "value": "true"<br/>}</pre> | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_create_alb_access_logs_bucket"></a> [create\_alb\_access\_logs\_bucket](#input\_create\_alb\_access\_logs\_bucket) | Create S3 bucket for ALB access logs. | `bool` | `false` | no |
| <a name="input_create_aws_ssm_bucket"></a> [create\_aws\_ssm\_bucket](#input\_create\_aws\_ssm\_bucket) | S3 | `bool` | `false` | no |
| <a name="input_create_backup_copy"></a> [create\_backup\_copy](#input\_create\_backup\_copy) | Optional override to backup\_plan\_rules to be able to disable copy | `bool` | `false` | no |
| <a name="input_create_backup_sns_topic"></a> [create\_backup\_sns\_topic](#input\_create\_backup\_sns\_topic) | SNS | `bool` | `false` | no |
| <a name="input_create_backup_vault"></a> [create\_backup\_vault](#input\_create\_backup\_vault) | Controls if Backup Vault are to be created | `bool` | `false` | no |
| <a name="input_create_backup_vault_policy"></a> [create\_backup\_vault\_policy](#input\_create\_backup\_vault\_policy) | n/a | `bool` | `false` | no |
| <a name="input_create_instance_scheduler"></a> [create\_instance\_scheduler](#input\_create\_instance\_scheduler) | Instance Scheduler | `bool` | `false` | no |
| <a name="input_create_nlb_access_logs_bucket"></a> [create\_nlb\_access\_logs\_bucket](#input\_create\_nlb\_access\_logs\_bucket) | Create S3 bucket for NLB access logs. | `bool` | `false` | no |
| <a name="input_create_s3_vpc_endpoint"></a> [create\_s3\_vpc\_endpoint](#input\_create\_s3\_vpc\_endpoint) | Create an S3 gateway VPC endpoint so S3 traffic stays within the AWS network and can avoid NAT gateway charges. | `bool` | `false` | no |
| <a name="input_create_ssm_vpc_endpoint"></a> [create\_ssm\_vpc\_endpoint](#input\_create\_ssm\_vpc\_endpoint) | Create an SSM Interface VPC endpoint so SSM traffic stays within the AWS network and can avoid NAT gateway need. | `bool` | `false` | no |
| <a name="input_dryrun"></a> [dryrun](#input\_dryrun) | n/a | `string` | `"false"` | no |
| <a name="input_enable_access_logs"></a> [enable\_access\_logs](#input\_enable\_access\_logs) | Enable ALB access logs to S3. | `bool` | `true` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | n/a | `number` | `600` | no |
| <a name="input_lb_ingress_cidr_blocks"></a> [lb\_ingress\_cidr\_blocks](#input\_lb\_ingress\_cidr\_blocks) | CIDR blocks allowed to reach load balancers. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_nlb_access_logs_bucket"></a> [nlb\_access\_logs\_bucket](#input\_nlb\_access\_logs\_bucket) | Optional existing S3 bucket name for NLB access logs. If empty and enable\_access\_logs=true, the module will create one. | `string` | `""` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - Variables - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - Common | `string` | n/a | yes |
| <a name="input_private_route_table_ids"></a> [private\_route\_table\_ids](#input\_private\_route\_table\_ids) | Explicit private route table IDs. If set, these are used instead of private\_route\_table\_name\_filter. | `list(string)` | `[]` | no |
| <a name="input_private_route_table_name_filter"></a> [private\_route\_table\_name\_filter](#input\_private\_route\_table\_name\_filter) | Private route table Name tag filter used when private\_route\_table\_ids is empty. | `string` | `null` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Explicit private subnet IDs. If set, these are used instead of private\_subnet\_name\_filter. | `list(string)` | `[]` | no |
| <a name="input_private_subnet_name_filter"></a> [private\_subnet\_name\_filter](#input\_private\_subnet\_name\_filter) | Private subnet Name tag filter used when private\_subnet\_ids is empty. | `string` | `null` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Explicit public subnet IDs. If set, these are used instead of public\_subnet\_name\_filter. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_name_filter"></a> [public\_subnet\_name\_filter](#input\_public\_subnet\_name\_filter) | Public subnet Name tag filter used when public\_subnet\_ids is empty. | `string` | `null` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | n/a | `string` | `"python3.12"` | no |
| <a name="input_s3_vpc_endpoint_policy"></a> [s3\_vpc\_endpoint\_policy](#input\_s3\_vpc\_endpoint\_policy) | Optional custom policy JSON for the S3 VPC endpoint. If null, the default full-access endpoint policy is used. | `string` | `null` | no |
| <a name="input_s3_vpc_endpoint_route_table_ids"></a> [s3\_vpc\_endpoint\_route\_table\_ids](#input\_s3\_vpc\_endpoint\_route\_table\_ids) | Optional explicit route table IDs for the S3 VPC endpoint. If empty, private\_route\_table\_ids are used. | `list(string)` | `[]` | no |
| <a name="input_sns_protocol"></a> [sns\_protocol](#input\_sns\_protocol) | n/a | `string` | `"https"` | no |
| <a name="input_sns_subscriber"></a> [sns\_subscriber](#input\_sns\_subscriber) | n/a | `string` | `""` | no |
| <a name="input_sns_subscriber_auto_confirms"></a> [sns\_subscriber\_auto\_confirms](#input\_sns\_subscriber\_auto\_confirms) | True if subscriber can auto confirm like for example Opsgenie | `bool` | `true` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | EC2 | `any` | n/a | yes |
| <a name="input_start_disabled"></a> [start\_disabled](#input\_start\_disabled) | n/a | `bool` | `false` | no |
| <a name="input_start_expression"></a> [start\_expression](#input\_start\_expression) | n/a | `string` | `"cron(0 7 ? * MON-FRI *)"` | no |
| <a name="input_stop_expression"></a> [stop\_expression](#input\_stop\_expression) | n/a | `string` | `"cron(0 19 ? * MON-FRI *)"` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | n/a | `string` | `"Scheduler:Enabled"` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | n/a | `string` | `"Europe/Stockholm"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Explicit VPC ID. If set, this is used instead of vpc\_name\_filter. | `string` | `null` | no |
| <a name="input_vpc_name_filter"></a> [vpc\_name\_filter](#input\_vpc\_name\_filter) | VPC Name tag filter used when vpc\_id is not set. | `string` | `null` | no |
| <a name="input_vpn_amazon_side_asn"></a> [vpn\_amazon\_side\_asn](#input\_vpn\_amazon\_side\_asn) | n/a | `number` | `64512` | no |
| <a name="input_vpn_connections"></a> [vpn\_connections](#input\_vpn\_connections) | VPN | `map` | `{}` | no |
| <a name="input_vpn_customer_side_asn"></a> [vpn\_customer\_side\_asn](#input\_vpn\_customer\_side\_asn) | n/a | `number` | `65000` | no |
| <a name="input_vpn_dh_group_number"></a> [vpn\_dh\_group\_number](#input\_vpn\_dh\_group\_number) | n/a | `string` | `"14"` | no |
| <a name="input_vpn_dpd_timeout_action"></a> [vpn\_dpd\_timeout\_action](#input\_vpn\_dpd\_timeout\_action) | n/a | `string` | `"clear"` | no |
| <a name="input_vpn_dpd_timeout_seconds"></a> [vpn\_dpd\_timeout\_seconds](#input\_vpn\_dpd\_timeout\_seconds) | n/a | `number` | `30` | no |
| <a name="input_vpn_encryption_algorithm"></a> [vpn\_encryption\_algorithm](#input\_vpn\_encryption\_algorithm) | n/a | `string` | `"AES256"` | no |
| <a name="input_vpn_ike_version"></a> [vpn\_ike\_version](#input\_vpn\_ike\_version) | n/a | `string` | `"ikev2"` | no |
| <a name="input_vpn_integrity_algorithm"></a> [vpn\_integrity\_algorithm](#input\_vpn\_integrity\_algorithm) | n/a | `string` | `"SHA2-256"` | no |
| <a name="input_vpn_log_retention_in_days"></a> [vpn\_log\_retention\_in\_days](#input\_vpn\_log\_retention\_in\_days) | n/a | `number` | `3` | no |
| <a name="input_vpn_phase1_lifetime_seconds"></a> [vpn\_phase1\_lifetime\_seconds](#input\_vpn\_phase1\_lifetime\_seconds) | n/a | `number` | `28800` | no |
| <a name="input_vpn_phase2_lifetime_seconds"></a> [vpn\_phase2\_lifetime\_seconds](#input\_vpn\_phase2\_lifetime\_seconds) | n/a | `number` | `3600` | no |
| <a name="input_vpn_preshared_key"></a> [vpn\_preshared\_key](#input\_vpn\_preshared\_key) | n/a | `string` | `""` | no |
| <a name="input_vpn_rekey_margin_time_seconds"></a> [vpn\_rekey\_margin\_time\_seconds](#input\_vpn\_rekey\_margin\_time\_seconds) | n/a | `number` | `540` | no |
| <a name="input_vpn_startup_action"></a> [vpn\_startup\_action](#input\_vpn\_startup\_action) | n/a | `string` | `"add"` | no |
| <a name="input_vpn_static_routes_only"></a> [vpn\_static\_routes\_only](#input\_vpn\_static\_routes\_only) | n/a | `bool` | `true` | no |
| <a name="input_zabbix_cidr_blocks"></a> [zabbix\_cidr\_blocks](#input\_zabbix\_cidr\_blocks) | SG | `list(string)` | <pre>[<br/>  "49.13.250.58/32",<br/>  "10.147.0.70/32"<br/>]</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alb_access_logs_bucket"></a> [alb\_access\_logs\_bucket](#output\_alb\_access\_logs\_bucket) | n/a |
| <a name="output_ansible_key_name"></a> [ansible\_key\_name](#output\_ansible\_key\_name) | EC2 |
| <a name="output_aws_ssm_bucket"></a> [aws\_ssm\_bucket](#output\_aws\_ssm\_bucket) | S3 |
| <a name="output_iam_instance_profile"></a> [iam\_instance\_profile](#output\_iam\_instance\_profile) | IAM |
| <a name="output_nlb_access_logs_bucket"></a> [nlb\_access\_logs\_bucket](#output\_nlb\_access\_logs\_bucket) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_s3_vpc_endpoint_id"></a> [s3\_vpc\_endpoint\_id](#output\_s3\_vpc\_endpoint\_id) | n/a |
| <a name="output_sg_alb_id"></a> [sg\_alb\_id](#output\_sg\_alb\_id) | Security groups |
| <a name="output_sg_artifactory_id"></a> [sg\_artifactory\_id](#output\_sg\_artifactory\_id) | n/a |
| <a name="output_sg_gitlab_id"></a> [sg\_gitlab\_id](#output\_sg\_gitlab\_id) | n/a |
| <a name="output_sg_nlb_id"></a> [sg\_nlb\_id](#output\_sg\_nlb\_id) | n/a |
| <a name="output_sg_sonarqube_id"></a> [sg\_sonarqube\_id](#output\_sg\_sonarqube\_id) | n/a |
| <a name="output_sg_zabbix_id"></a> [sg\_zabbix\_id](#output\_sg\_zabbix\_id) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC |
| <a name="output_vpn_routes"></a> [vpn\_routes](#output\_vpn\_routes) | n/a |
<!-- END_TF_DOCS -->

## Notes / Gotchas

- This module does not create ALB/NLB resources; it creates related security groups and optional log buckets.
- For VPC/subnet/route table resolution, provide either explicit IDs or valid Name filters; unresolved values can break endpoint or VPN resources.
- `ssh_public_key` is required.
- `create_backup_sns_topic` is only effective when `create_backup_vault = true`.
- `enable_access_logs` exists as an input but is currently not referenced by resources in this module.
- To auto-refresh the tables in CI, run `terraform-docs markdown table --output-file README.md --output-mode inject .`.
