# Terraform NLB Module

Creates an AWS Network Load Balancer (NLB) with:

- TCP listener on port 22 (SSH)
- TLS listener on port 443 (HTTPS)
- Two target groups (SSH and HTTPS)
- Instance attachments
- Optional access logs to S3 (auto-created or existing bucket)
- Cross-zone load balancing (enabled by default)
- Deletion protection (enabled by default)

---

# Module Location

```
modules/nlb
```

---

# Usage

## Basic Example

```hcl
module "gitlab_nlb" {
  source      = "../../modules/nlb"
  prefix      = local.prefix
  stack_name  = "awevltest02"
  common_tags = local.common_tags

  internal            = false
  vpc_id              = module.core.vpc_id
  subnet_ids          = module.core.public_subnet_ids
  security_group_ids  = [module.core.sg_nlb_id]
  instance_ids        = module.gitlab_ec2.instance_ids

  cert_arn            = "arn:aws:acm:eu-north-1:123456789012:certificate/xxxx"
}
```

---

# Inputs

## Common

| Name | Type | Default | Description |
|------|------|---------|-------------|
| prefix | string | n/a | Naming prefix used across the stack |
| stack_name | string | n/a | Stack / environment name |
| common_tags | map(string) | {} | Tags applied to all resources |

## NLB

| Name | Type | Default | Description |
|------|------|---------|-------------|
| internal | bool | false | true = internal NLB, false = internet-facing |
| vpc_id | string | n/a | VPC ID for target groups |
| subnet_ids | list(string) | n/a | Subnet IDs for the NLB |
| security_group_ids | list(string) | [] | Security groups attached to NLB |
| instance_ids | list(string) | n/a | EC2 instance IDs to register as targets |
| cert_arn | string | n/a | ACM certificate ARN for TLS listener |
| ssl_policy | string | ELBSecurityPolicy-TLS13-1-2-2021-06 | TLS security policy |
| deregistration_delay | number | 60 | Target group deregistration delay (seconds) |
| health_check_port | string | "traffic-port" | Health check port |
| enable_deletion_protection | bool | true | Enable deletion protection |
| enable_cross_zone_load_balancing | bool | true | Enable cross-zone load balancing |

## Access Logs (S3)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| enable_access_logs | bool | true | Enable NLB access logs |
| access_logs_bucket | string | "" | Existing S3 bucket for logs (if empty and enabled, module creates one) |

---

# Outputs

| Name | Description |
|------|-------------|
| nlb_arn | ARN of the NLB |
| nlb_dns_name | DNS name of the NLB |
| listener_ssh_arn | ARN of SSH listener |
| listener_https_arn | ARN of HTTPS listener |
| target_group_ssh_arn | ARN of SSH target group |
| target_group_https_arn | ARN of HTTPS target group |

Example:

```hcl
output "nlb_dns" {
  value = module.gitlab_nlb.nlb_dns_name
}
```

---

# Behavior & Implementation Notes

- Creates a Network Load Balancer (`load_balancer_type = "network"`).
- Port 22 uses TCP listener and target group.
- Port 443 uses TLS listener with ACM certificate.
- HTTPS target group uses source IP stickiness.
- Health checks use TCP on configurable port.
- Target group names are truncated to 32 characters to satisfy AWS limits.
- Cross-zone load balancing is enabled by default.
- Deletion protection is enabled by default.

---

# Access Logs Behavior

If:

```
enable_access_logs = true
access_logs_bucket = ""
```

The module:

- Creates a dedicated S3 bucket
- Enables:
  - Server-side encryption (AES256)
  - Versioning
  - Lifecycle rule (90 days expiration, 30 days noncurrent)
  - Public access block
  - Proper bucket policy for log delivery

If `access_logs_bucket` is provided, logs will be written there instead.

---

# Naming Convention

Resources are named:

```
<prefix>-<stack_name>
```

Target groups:

```
<prefix>-<stack_name>-ssh
<prefix>-<stack_name>-https
```

S3 logs bucket (if created):

```
<prefix>-nlb-access-logs-<random>
```

---

# Example Project Structure

```
terraform/
├── environment/
│   └── test/
│       └── nlb.tf
└── modules/
    └── nlb/
        ├── main resources (*.tf)
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

---

# Important Notes

- `cert_arn` must be a valid ACM certificate in the same region.
- Ensure subnets match the intended exposure (public for internet-facing, private for internal).
- Target group names are limited to 32 characters.
- Deletion protection must be disabled before destroying the NLB.
- If using an existing S3 bucket for logs, ensure it allows ELB log delivery.

---

# Requirements

- Terraform >= 1.3.0
- AWS Provider compatible with your Terraform version
