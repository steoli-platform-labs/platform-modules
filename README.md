# platform-modules

Reusable Terraform modules for the AWS Platform Labs project.

## Purpose

This repository contains versioned, reusable infrastructure building blocks. Environment-specific values and remote state configuration belong in `platform-live`.

## Repository Structure

```text
modules/
└── core/
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── versions.tf
```

## Usage

The core module is consumed from `platform-live/environments/dev`.

```hcl
module "core" {
  source = "../../../../platform-modules/modules/core"
  # ...
}
```

For published releases, consumers should use a Git tag instead of a local path.

## Validation

```bash
terraform fmt -check -recursive
./scripts/validate.sh
```

## Security Considerations

- No credentials or Terraform state may be committed.
- Workloads are placed in private subnets.
- Public subnet assignment does not automatically grant public IP addresses to future workloads.

## Related Repositories

- `platform-live`
- `platform-bootstrap`
- `docs`
