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
| `infra/src/variables.tf` | Top-level runtime variables (instance types, node sizes, etc.) |
| `infra/src/module_variables_eks.tf` | Variable declarations that map to the EKS module inputs |
| `infra/src/module_variables_vpc.tf` | Variable declarations that map to the VPC module inputs |
| `infra/src/outputs.tf` | Stack outputs (vpc, eks, sops config, kubectl command) |
| `infra/src/backend.tf` | HTTP backend for GitLab remote state + `required_providers` declarations |
| `infra/root.hcl` | Terragrunt root config — reads `default.json` + `env.json`, generates S3 backend |
| `infra/default.json` | Default input values shared by all environments |
| `infra/environments/dev/env.json` | Dev-specific input overrides |
| `infra/environments/qa/env.json` | QA-specific input overrides |
| `infra/environments/prod/env.json` | Prod-specific input overrides |
| `infra/environments/*/terragrunt.hcl` | Per-environment Terragrunt config — includes `root.hcl`, sets source |
| `gitlab-ci.yml` | GitLab pipeline (renamed to `.gitlab-ci.yml` by ENBUILD at repo creation) |
| `.github/workflows/infra-deploy.yaml` | GitHub Actions deploy workflow |
| `.github/workflows/infra-destroy.yaml` | GitHub Actions destroy workflow (manual) |

---

## Module Versions

| Module | Registry Source | Version |
|---|---|---|
| EKS | `terraform-aws-modules/eks/aws` | `21.15.1` |
| VPC | `terraform-aws-modules/vpc/aws` | `6.6.0` |

---

## Variable Naming Convention

The EKS module v21 renamed many variables from the v20 API. This repo uses a **wrapper pattern**: Terraform variables in `module_variables_eks.tf` keep the old familiar names (e.g. `cluster_endpoint_public_access`) and `eks.tf` maps them to the v21 module's new names (e.g. `endpoint_public_access`).

Key renames from v20 → v21 (handled in `eks.tf`):

| Terraform variable (our wrapper) | EKS module v21 argument |
|---|---|
| `cluster_name` | `name` |
| `cluster_version` | `kubernetes_version` |
| `cluster_enabled_log_types` | `enabled_log_types` |
| `cluster_endpoint_public_access` | `endpoint_public_access` |
| `cluster_endpoint_private_access` | `endpoint_private_access` |
| `cluster_encryption_config` | `encryption_config` |
| `attach_cluster_encryption_policy` | `attach_encryption_policy` |
| `create_cluster_security_group` | `create_security_group` |
| `cluster_security_group_*` | `security_group_*` |
| `cluster_timeouts` | `timeouts` |
| `cluster_addons_timeouts` | `addons_timeouts` |
| `cluster_identity_providers` | `identity_providers` |
| `cluster_encryption_policy_*` | `encryption_policy_*` |
| `create_cluster_primary_security_group_tags` | `create_primary_security_group_tags` |

**Removed in v21** (do not use): `create`, `enable_efa_support`, `fargate_profile_defaults`, `self_managed_node_group_defaults`, `eks_managed_node_group_defaults`.

**Added in v21** (available): `deletion_protection`, `force_update_version`, `upgrade_policy`, `compute_config`, `control_plane_scaling_config`, `remote_network_config`, `zonal_shift_config`, `kms_key_rotation_period_in_days`, `enable_auto_mode_custom_tags`, `create_auto_mode_iam_resources`, `create_node_iam_role`, `node_iam_role_*`.

---

## How Inputs Flow

```
infra/default.json          (base defaults)
       +
infra/environments/<env>/env.json   (env overrides)
       +
root.hcl locals             (computed: cluster_name, environment, aws_region, stack_name)
       |
       v
   inputs = merge(default_vars, env_vars, computed)
       |
       v
infra/src/variables.tf + module_variables_*.tf   (Terraform variables)
       |
       v
infra/src/eks.tf + vpc.tf                        (module calls)
```

---

## How to Add a New Variable

1. Declare it in `infra/src/module_variables_eks.tf` (or `module_variables_vpc.tf` for VPC, or `variables.tf` for top-level).
2. Pass it in `infra/src/eks.tf` (or `vpc.tf`) as a module argument.
3. Set a default value in `infra/default.json`.
4. Override per-environment in `infra/environments/<env>/env.json` if needed.

---

## State Backend Selection

| How you run | Backend used |
|---|---|
| `terragrunt apply` (GitHub Actions) | S3 (`<stack>-<region>-<account>-tfstate`) — auto-created |
| `terraform apply` (GitLab CI) | GitLab HTTP remote state |

The Terragrunt-generated `backend.tf` overwrites the checked-in `backend.tf` at runtime. The checked-in `backend.tf` (HTTP backend) is only active when running Terraform directly.

---

## Environment Branch Mapping (GitHub Actions)

| Git branch | Environment directory |
|---|---|
| `dev` | `infra/environments/dev/` |
| `qa` | `infra/environments/qa/` |
| `main` / `release/*` | `infra/environments/prod/` |

---

## GovCloud Compatibility

- All IAM ARNs use `data.aws_partition.current.partition` — resolves to `aws-us-gov` automatically.
- Set `AWS_DEFAULT_REGION` to `us-gov-west-1` or `us-gov-east-1`.
- Verify EKS version availability before deploying to GovCloud (it lags commercial by ~3–6 months).
- In air-gapped environments, mirror Terraform modules or revert module sources to local paths.

---

## Common Tasks

**Change EKS version:** Update `cluster_version` in `infra/default.json` (or per `env.json`).

**Add a new environment:** Create `infra/environments/<name>/terragrunt.hcl` (copy from dev) and `infra/environments/<name>/env.json`.

**Add a new AWS addon:** Add an entry under the `addons` block in `infra/src/eks.tf`.

**Use existing VPC:** Set `"create_vpc": false`, `"vpc_id": "..."`, `"subnet_ids": [...]` in the appropriate `env.json`.

**Enable registry1 mirror (Iron Bank / air-gapped):** Set `"create_registry1_mirror": true` and `"registry1_mirror_proxy_address": "http://<proxy>:5000"` in `env.json`.

---

## Do Not

- Do not add business logic to `root.hcl` — keep it limited to state config and input merging.
- Do not hardcode ARNs with `arn:aws:` — always use `data.aws_partition.current.partition`.
- Do not hardcode regions — use `data.aws_region.current.name` or the `aws_region` local.
- Do not add HCL comments (`//`) in JSON files — JSON does not support comments.
- Do not modify `infra/src/backend.tf` — it is intentionally minimal (GitLab injects the config).
- Do not commit secrets or AWS credentials.
