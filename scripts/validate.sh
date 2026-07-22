#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

terraform fmt -check -recursive "${repo_root}"

for module_dir in "${repo_root}"/modules/*; do
  [[ -d "${module_dir}" ]] || continue
  terraform -chdir="${module_dir}" init -backend=false
  terraform -chdir="${module_dir}" validate
done

echo "platform-modules validation passed"
