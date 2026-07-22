# Terraform ALB Rule Module

Creates an AWS Application Load Balancer (ALB) target group, listener rule and attaches instances to the target group.

This module provides:

- An `aws_lb_target_group` for your backend instances
- An `aws_lb_listener_rule` with host-header condition
- `aws_lb_target_group_attachment` resources to attach instances to the TG
- Configurable health check settings
- Configurable deregistration delay
- Tagging via `common_tags`

---

# Module Location

```
modules/alb-rule
```

---

# Usage

## Basic Usage

```hcl
module "gitlab_alb_rule" {
  source      = "../../modules/alb-rule"
  prefix      = local.prefix
  stack_name  = "awevltest02"
  common_tags = local.common_tags

  vpc_id       = module.core.vpc_id
  listener_arn = module.alb.listener_arn
  priority     = 100
  hostnames    = ["gitlab.example.com"]
  instance_ids = module.gitlab_ec2.instance_ids

  # Optional overrides
  # backend_port         = 80
  # backend_protocol     = "HTTP"
  # deregistration_delay = 60
}
```

This creates:

- A target group named from `<prefix>-<stack_name>` (trimmed to 32 chars)
- A listener rule on the provided listener ARN
- Target group attachments for the provided instances

---

# Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `prefix` | string | n/a | Naming prefix used across the stack |
| `stack_name` | string | n/a | Stack / environment name |
| `common_tags` | map(string) | `{}` | Tags applied to resources |
| `vpc_id` | string | n/a | VPC id for the target group |
| `listener_arn` | string | n/a | ALB listener ARN (HTTP or HTTPS) |
| `priority` | number | n/a | Unique listener rule priority on this listener |
| `hostnames` | list(string) | n/a | Host header values (e.g. `["gitlab.example.com"]`) |
| `instance_ids` | list(string) | n/a | Instance IDs to attach to the target group |
| `backend_port` | number | `80` | Backend port on the instances |
| `backend_protocol` | string | `"HTTP"` | Protocol for the target group |
| `deregistration_delay` | number | `60` | Deregistration delay in seconds |

## Health Check Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `health_check_path` | string | `"/"` | Health check path |
| `health_check_protocol` | string | `"HTTP"` | Health check protocol |
| `health_check_matcher` | string | `"200-399"` | HTTP matcher codes |
| `health_check_healthy_threshold` | number | `2` | Healthy threshold |
| `health_check_unhealthy_threshold` | number | `2` | Unhealthy threshold |
| `health_check_interval` | number | `30` | Interval between health checks (seconds) |
| `health_check_timeout` | number | `5` | Health check timeout (seconds) |

---

# Outputs

| Name | Description |
|------|-------------|
| `target_group_arn` | ARN of the created target group |
| `listener_rule_arn` | ARN of the created listener rule |

Example:

```hcl
output "gitlab_tg_arn" {
  value = module.gitlab_alb_rule.target_group_arn
}
```

---

# Notes / Gotchas

- Target group names are limited to 32 characters. The module trims the name automatically.
- `priority` must be unique per listener.
- This module creates host-header based routing only.
- Health check defaults are suitable for standard HTTP apps but should be adjusted if needed.

---

# Example Project Structure

```
terraform/
├── environment/
│   └── test/
│       └── alb-rule.tf
└── modules/
    └── alb-rule/
        ├── alb.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

---

# Requirements

- Terraform >= 1.3.0
- AWS Provider compatible with your environment
