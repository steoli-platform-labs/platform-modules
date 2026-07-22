# Terraform AWS S3 Module

This module creates one or multiple AWS S3 buckets using a single module call.

It supports:

- Creating multiple buckets from a list or a map
- Optional per-bucket configuration
- Versioning
- Server-side encryption (AES256) — enforced by the module
- Lifecycle rules
- Public access blocking (enabled by default)
- Common tagging

---

# Module Location

```
modules/s3
```

---

# Usage

## Basic Usage (List of Buckets)

Use this when you just want to create multiple buckets with default settings.

```hcl
module "s3" {
  source      = "../../modules/s3"
  prefix      = local.prefix
  stack_name  = "awevltest02"
  common_tags = local.common_tags

  buckets = [
    "artifacts",
    "registry",
    "backups"
  ]
}
```

This creates buckets using the naming convention:

```
<prefix>-<stack_name>-<bucket_name>
```

Example:

```
myapp-awevltest02-artifacts
myapp-awevltest02-backups
myapp-awevltest02-logs
```

---

## Advanced Usage (Map with Per-Bucket Configuration)

Use this when you need custom settings per bucket.

```hcl
module "s3" {
  source      = "../../modules/s3"
  prefix      = local.prefix
  stack_name  = "awevltest02"
  common_tags = local.common_tags

  buckets = {
    artifacts = {
      versioning = true
      tags = {
        Purpose = "ci-artifacts"
      }
    }

    backups = {
      versioning = true
      lifecycle_rules = [
        {
          id              = "expire-old"
          expiration_days = 365
        }
      ]
    }

    logs = {
      versioning = false
      lifecycle_rules = [
        {
          id                         = "cleanup-noncurrent"
          noncurrent_expiration_days  = 30
        }
      ]
    }
  }
}
```

---

# Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| prefix | string | n/a | Naming prefix used across the stack |
| stack_name | string | n/a | Stack / environment name |
| buckets | list(string) or map(object) | n/a | Buckets to create |
| common_tags | map(string) | {} | Tags applied to all buckets |
| force_destroy | bool | false | Allow deletion of non-empty buckets |
| default_versioning | bool | true | Default versioning behavior |

Note: Server-side encryption is enforced as AES256 by the module (not configurable in this simplified version).

---

# Per-Bucket Configuration Options (Map Mode)

When using the map input, each bucket can define:

```hcl
{
  versioning         = bool
  force_destroy      = bool
  tags               = map(string)
  lifecycle_rules = [
    {
      id                          = string
      enabled                     = bool
      expiration_days             = number
      noncurrent_expiration_days  = number
    }
  ]
}
```

All attributes are optional.

---

# Outputs

| Name | Description |
|------|-------------|
| bucket_names | Map of bucket names created |
| bucket_arns  | Map of bucket ARNs |
| bucket_ids   | Map of bucket IDs (same as names for S3) |

Example:

```hcl
output "s3_bucket_names" {
  value = module.s3.bucket_names
}
```

---

# Security Defaults

The module enforces the following best practices by default:

- Public access blocked
- Server-side encryption (AES256) enabled
- Versioning enabled (unless overridden per-bucket)

---

# Important Notes

## S3 Bucket Names Must Be Globally Unique

Bucket names must be unique across all AWS accounts globally.

If there is a risk of collision, consider including:

- Account ID
- Region
- Additional environment identifiers

Example modification:

```hcl
bucket = "${var.prefix}-${var.stack_name}-${data.aws_caller_identity.current.account_id}-${each.key}"
```

---

# Example Project Structure

```
terraform/
├── environment/
│   └── test/
│       └── s3.tf
└── modules/
    └── s3/
        ├── s3.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

---

# Requirements

- Terraform >= 1.3.0
- AWS Provider >= 5.0
