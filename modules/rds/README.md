# Terraform RDS Module

Creates an AWS RDS Postgres instance with:

- DB subnet group
- Dedicated security group
- Optional random password generation
- Storage encryption enabled
- Optional Multi-AZ
- Optional storage autoscaling
- Backup and maintenance configuration
- Sensible defaults (lab-friendly, adjustable for production)

---

# Module Location

```
modules/rds
```

---

# Usage

## Basic Example

```hcl
module "db" {
  source = "../../modules/rds"

  prefix                     = local.prefix
  stack_name                 = "awevltest02"
  vpc_id                     = module.core.vpc_id
  subnet_ids                 = module.core.private_subnet_ids
  allowed_security_group_ids = [module.core.sg_app_id]

  username          = "postgres"
  # password        = "supersecret"  # Optional (auto-generated if empty)

  instance_class    = "db.t4g.medium"
  allocated_storage = 50

  common_tags       = local.common_tags
}
```

---

# Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| prefix | string | n/a | Naming prefix used across the stack |
| stack_name | string | n/a | Stack / environment name |
| vpc_id | string | n/a | VPC id where DB security group is created |
| subnet_ids | list(string) | n/a | Private subnet IDs for DB subnet group |
| allowed_security_group_ids | list(string) | n/a | Security groups allowed to connect to Postgres |
| username | string | "postgres" | Master username |
| password | string | "" | Optional master password (auto-generated if empty) |
| instance_class | string | "db.t4g.medium" | RDS instance class |
| allocated_storage | number | 50 | Allocated storage (GB) |
| max_allocated_storage | number | 0 | Max storage for autoscaling (0 disables) |
| multi_az | bool | false | Enable Multi-AZ |
| engine_version | string | "16" | Postgres engine version |
| storage_type | string | "gp3" | Storage type |
| apply_immediately | bool | true | Apply changes immediately |
| skip_final_snapshot | bool | true | Skip final snapshot on delete |
| deletion_protection | bool | true | Protect RDS from deletion |
| backup_retention_period | number | 31 | Days to retain backups |
| allow_major_version_upgrade | bool | false | Allow major version upgrades |
| backup_window | string | "22:00-23:59" | Preferred backup window |
| maintenance_window | string | "Sun:20:00-Sun:21:59" | Preferred maintenance window |
| common_tags | map(string) | {} | Tags applied to all resources |

---

# Outputs

| Name | Description |
|------|-------------|
| endpoint | RDS endpoint hostname |
| port | RDS port |
| security_group_id | Security group ID created for DB |
| username | Master username |
| password | Master password (sensitive output) |

Example:

```hcl
output "db_endpoint" {
  value = module.db.endpoint
}
```

---

# Behavior & Notes

- If `password` is empty, a secure 24-character random password is generated.
- Storage encryption is enabled by default.
- Storage autoscaling is enabled when `max_allocated_storage > 0`.
- Security group allows inbound Postgres (5432) only from `allowed_security_group_ids`.
- Defaults are lab-friendly (`apply_immediately = true`, `skip_final_snapshot = true`). Adjust for production.

---

# Naming

Resources are named using:

```
<prefix>-<stack_name>
```

Ensure uniqueness within the AWS account and region.

---

# Example Project Structure

```
terraform/
├── environment/
│   └── test/
│       └── rds.tf
└── modules/
    └── rds/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

---

# Requirements

- Terraform >= 1.3.0
- AWS Provider compatible with your Terraform version
