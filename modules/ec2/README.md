# Terraform EC2 Module

This module creates one or more EC2 instances with attached EBS data volumes, user-data templating, and sensible security defaults.

It includes:

- `aws_instance` resources (count-based)
- Separate encrypted `aws_ebs_volume` per instance
- `aws_volume_attachment` for data volumes
- Latest Ubuntu 24.04 AMI by default (Canonical owner)
- Round-robin subnet placement
- IMDSv2 enforced by default
- API termination protection enabled by default
- Consistent tagging via `prefix`, `stack_name`, and `common_tags`

---

# Module Location

```
modules/ec2
```

---

# Usage

## Basic Example

```hcl
module "gitlab_ec2" {
  source               = "../../modules/ec2"
  prefix               = local.prefix
  stack_name           = "awevltest02"
  ansible_roles        = ["gitlab"]
  instance_type        = "t3.large"
  iam_instance_profile = module.core.iam_instance_profile
  subnet_ids           = module.core.private_subnet_ids
  security_group_ids   = [module.core.sg_zabbix_id, module.core.sg_gitlab_id]
  key_name             = module.core.ansible_key_name
  root_volume_size     = 50
  data_volume_size     = 100
  common_tags          = local.common_tags
  instance_count       = 1
}
```

## Multiple Instances (Round-Robin Subnets)

```hcl
module "app_ec2" {
  source         = "../../modules/ec2"
  prefix         = local.prefix
  stack_name     = "app01"
  instance_type  = "t3.medium"
  subnet_ids     = module.core.private_subnet_ids
  security_group_ids = [module.core.sg_app_id]
  instance_count = 3
}
```

Instances will be distributed across the provided `subnet_ids`.

---

# Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| prefix | string | n/a | Naming prefix used across the stack |
| stack_name | string | n/a | Stack / environment name |
| ansible_roles | list(string) | [] | Ansible roles assigned (stored as tag) |
| instance_count | number | 1 | Number of instances to create |
| ami_id | string | "" | Custom AMI ID. If empty, latest Ubuntu 24.04 is used |
| instance_type | string | n/a | EC2 instance type |
| subnet_ids | list(string) | n/a | Subnet IDs (must contain at least one) |
| security_group_ids | list(string) | n/a | Security group IDs |
| iam_instance_profile | string | null | IAM instance profile name |
| root_volume_size | number | 50 | Root volume size (GB) |
| data_volume_size | number | 100 | Additional data volume size (GB) |
| ebs_mount_vars | map(any) | default map | Variables passed to postinstall template |
| efs_mount_point | string | "/data/nfs" | Placeholder for EFS mount |
| efs_mount_options | string | default options | Placeholder for EFS mount options |
| common_tags | map(string) | {} | Tags applied to all resources |
| ec2_disable_api_termination | bool | true | Enable termination protection |
| ec2_http_endpoint | string | "enabled" | IMDS endpoint (enabled/disabled) |
| ec2_http_tokens | string | "required" | IMDS token requirement (optional/required) |
| key_name | string | "" | EC2 key pair name (empty = none attached) |

---

# Outputs

| Name | Description |
|------|-------------|
| instance_ids | List of EC2 instance IDs |
| private_ips | List of private IP addresses |

Example:

```hcl
output "instance_ids" {
  value = module.gitlab_ec2.instance_ids
}
```

---

# Behavior & Implementation Notes

- Uses latest Ubuntu 24.04 AMI from Canonical if `ami_id` is not set.
- Root and data volumes are:
  - Type: `gp3`
  - Encrypted: true
- Subnet placement is round-robin using modulo logic.
- User data is rendered from:

```
templates/postinstall.tpl
```

- The following attributes are ignored in lifecycle to prevent unnecessary recreation:
  - `ami`
  - `volume_tags`
  - `root_block_device[0].tags`
  - `user_data`

---

# Naming Convention

Instances are named:

```
<prefix>-<stack_name><letter>
```

Example:

```
app-awevltest02a
app-awevltest02b
```

Data volumes are named:

```
<prefix>-<stack_name><letter>-data
```

Note: The module uses single-letter suffixes (a–z). If you create more than 26 instances, naming must be adjusted.

---

# Security Defaults

- Root and data volumes encrypted
- IMDSv2 required by default
- API termination protection enabled
- No SSH key attached unless `key_name` is provided

---

# Example Project Structure

```
terraform/
├── environment/
│   └── test/
│       └── ec2.tf
└── modules/
    └── ec2/
        ├── main resources (*.tf)
        ├── templates/
        │   └── postinstall.tpl
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

---

# Requirements

- Terraform >= 1.3.0
- AWS Provider compatible with your Terraform version
