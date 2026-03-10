# AGENTS.md — Coding Agent Guide

This file provides context for AI coding agents (GitHub Copilot, Cursor, Claude, etc.) working in this repository.

---

## What This Repo Does

This is a **template repository** that provisions an AWS EKS cluster using Terraform/Terragrunt. It supports two CI/CD paths:
- **GitHub Actions** — uses Terragrunt, stores state in AWS S3 (auto-created)
- **GitLab CI/CD** — uses Terraform directly, stores state in GitLab remote state

---

## Key Files and Their Roles

| File | Role |
|---|---|
| `infra/src/eks.tf` | EKS module call + SSH key + SOPS IAM policy |
| `infra/src/vpc.tf` | VPC module call |
| `infra/src/main.tf` | Locals, data sources, mirror proxy config |
| `infra/src/providers.tf` | AWS + Kubernetes provider configuration |
| `infra/src/variables.tf` | Top-level runtime variables |
| `infra/src/module_variables_eks.tf` | EKS module variable declarations (wrapper pattern) |
| `infra/src/module_variables_vpc.tf` | VPC module variable declarations |
| `infra/src/outputs.tf` | Stack outputs (vpc, eks, sops config, kubectl command) |
| `infra/src/backend.tf` | HTTP backend for GitLab remote state |
| `infra/root.hcl` | Terragrunt root config — reads JSON, generates S3 backend |
| `infra/default.json` | Default input values shared by all environments |
| `infra/environments/*/env.json` | Per-environment overrides |
| `infra/environments/*/terragrunt.hcl` | Per-environment Terragrunt config |
| `.github/workflows/infra-deploy.yaml` | GitHub Actions deploy workflow |
| `.github/workflows/infra-destroy.yaml` | GitHub Actions destroy workflow (manual) |

---

## Build, Lint & Test Commands

### Local Development (Makefile)
```bash
make fmt                              # Format Terraform and Terragrunt files
make init ENVIRONMENT=dev             # Initialize environment
make plan ENVIRONMENT=dev             # Plan changes
make apply ENVIRONMENT=dev           # Apply (auto-approve)
make destroy ENVIRONMENT=dev         # Destroy resources
make deploy ENVIRONMENT=dev          # Run-all apply
```

### Single Environment
```bash
cd infra/environments/dev && terragrunt plan    # Dev plan
cd infra/environments/qa && terragrunt plan     # QA plan
cd infra/environments/prod && terragrunt plan  # Prod plan
```

### GitHub Actions CI
Runs on every push/PR: `terraform fmt` → `terragrunt init` → `tfsec` (security, soft-fail CRITICAL) → `terragrunt plan` (PR) / `apply` (push)

---

## Code Style Guidelines

### General Principles
- **Terragrunt for GitHub Actions** — All changes work with Terragrunt workflow
- **Terraform directly for GitLab CI** — The checked-in `backend.tf` (HTTP) is for GitLab
- **Keep `root.hcl` minimal** — Only state config and input merging; no business logic

### Terraform (.tf) Files
- Run `terraform fmt` before committing — Consistent formatting
- Use **wrapper variables** in `module_variables_*.tf` — API stability across module versions
- Map wrapper names → module names in `eks.tf`/`vpc.tf` — Avoid breaking changes on upgrades
- Use `data.aws_partition.current.partition` for ARNs — Supports commercial AWS and GovCloud
- Use `data.aws_region.current.name` or `aws_region` local — Avoid hardcoded regions

### Terragrunt (.hcl) Files
- Run `terragrunt hclfmt` before committing — HCL-specific formatting
- Use `try()` when reading JSON files — Gracefully handles missing files
- Keep `inputs = merge(defaults, env_overrides, computed)` pattern — Prevents override of computed values

### JSON Configuration Files
- **No comments** in JSON (`//` is invalid) — JSON does not support comments
- Use double quotes only — Standard JSON trailing commas — Valid format
- No JSON requirement
- Sort keys alphabetically — Consistent diffs

### Variable Naming
| Context | Convention | Example |
|---|---|---|
| Terraform variables | snake_case | `cluster_version`, `instance_types` |
| JSON keys | camelCase | `"clusterVersion"`, `"instanceTypes"` |
| Local values | snake_case | `local.stack_name` |
| Outputs | snake_case | `eks_cluster_arn` |

### Error Handling
- Use `try()` for optional values that may not exist
- Use `can()` to check if a function will succeed before calling
- Provide meaningful error messages in `validation` blocks

### Imports & References
- Always pin module version: `source = "terraform-aws-modules/eks/aws//.??"`
- Reference variables from `module_variables_*.tf` in module calls
- Use `depends_on` sparingly — prefer implicit dependencies

---

## Module Versions
| Module | Registry Source | Version |
|---|---|---|
| EKS | `terraform-aws-modules/eks/aws` | `21.15.1` |
| VPC | `terraform-aws-modules/vpc/aws` | `6.6.0` |

---

## Variable Naming Convention (Wrapper Pattern)
The EKS module v21 renamed variables from v20. This repo uses wrapper variables in `module_variables_eks.tf` (e.g., `cluster_endpoint_public_access`) and maps them to v21 names in `eks.tf` (e.g., `endpoint_public_access`).

**Key renames (v20 → v21):** `cluster_name` → `name`, `cluster_version` → `kubernetes_version`, `cluster_endpoint_public_access` → `endpoint_public_access`, etc.

**Removed in v21:** `create`, `enable_efa_support`, `fargate_profile_defaults`, `self_managed_node_group_defaults`, `eks_managed_node_group_defaults`.

**Added in v21:** `deletion_protection`, `force_update_version`, `upgrade_policy`, `compute_config`, `control_plane_scaling_config`, `kms_key_rotation_period_in_days`, `create_node_iam_role`, etc.

---

## How Inputs Flow
```
infra/default.json (base defaults) + infra/environments/<env>/env.json (env overrides) + root.hcl locals (computed: cluster_name, environment, aws_region)
       |
       v
   inputs = merge(default_vars, env_vars, computed)
       |
       v
infra/src/variables.tf + module_variables_*.tf (Terraform variables) → infra/src/eks.tf + vpc.tf (module calls)
```

---

## How to Add a New Variable
1. Declare in `infra/src/module_variables_eks.tf` (or `module_variables_vpc.tf`, or `variables.tf`)
2. Pass in `infra/src/eks.tf` (or `vpc.tf`) as a module argument
3. Set default in `infra/default.json`
4. Override per-environment in `infra/environments/<env>/env.json`

---

## State Backend Selection
| How you run | Backend used |
|---|---|
| `terragrunt apply` (GitHub Actions) | S3 — auto-created by Terragrunt |
| `terraform apply` (GitLab CI) | GitLab HTTP remote state |

---

## Environment Branch Mapping
| Git branch | Environment directory |
|---|---|
| `dev` | `infra/environments/dev/` |
| `qa` | `infra/environments/qa/` |
| `main` / `release/*` | `infra/environments/prod/` |

---

## GovCloud Compatibility
- All IAM ARNs use `data.aws_partition.current.partition` — resolves to `aws-us-gov` automatically
- Set `AWS_DEFAULT_REGION` to `us-gov-west-1` or `us-gov-east-1`
- Verify EKS version availability before deploying (GovCloud lags ~3–6 months)
- In air-gapped environments, mirror Terraform modules or revert to local paths

---

## Do Not
- Do not add business logic to `root.hcl` — keep it limited to state config and input merging
- Do not hardcode ARNs with `arn:aws:` — always use `data.aws_partition.current.partition`
- Do not hardcode regions — use `data.aws_region.current.name` or `aws_region` local
- Do not add HCL comments (`//`) in JSON files — JSON does not support comments
- Do not modify `infra/src/backend.tf` — intentionally minimal (GitLab injects config)
- Do not commit secrets or AWS credentials
