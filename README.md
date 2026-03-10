# AWS EKS — Template Repository

> **This is a template repository.** When you create a new repository from this template (via ENBUILD or manually), the generated repository contains a ready-to-deploy EKS cluster configuration. Do not deploy directly from this template.

This template provisions an Amazon EKS cluster using version **21.15.1** of the [terraform-aws-modules/eks](https://github.com/terraform-aws-modules/terraform-aws-eks) module and version **6.6.0** of the [terraform-aws-modules/vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

---

## Minimum IAM Policy

Refer to [min-iam-policy.json](./min-iam-policy.json) for the minimum IAM permissions required to deploy this stack. Ensure the deploying IAM role/user has these permissions before running any pipeline.

---

## Repository Structure

```
infra/
├── root.hcl                        # Terragrunt root config (GitHub Actions)
├── default.json                    # Default input variables for all environments
├── src/                            # Terraform source (used by both pipelines)
│   ├── backend.tf                  # HTTP backend (GitLab remote state)
│   ├── eks.tf                      # EKS cluster + node groups
│   ├── vpc.tf                      # VPC networking
│   ├── main.tf                     # Locals, data sources, KMS/SSH resources
│   ├── providers.tf                # AWS + Kubernetes providers
│   ├── variables.tf                # Top-level input variables
│   ├── outputs.tf                  # Stack outputs
│   ├── module_variables_eks.tf     # EKS module variable declarations
│   └── module_variables_vpc.tf     # VPC module variable declarations
└── environments/
    ├── dev/
    │   ├── terragrunt.hcl          # Includes root.hcl (GitHub Actions)
    │   └── env.json                # Dev environment overrides
    ├── qa/
    │   ├── terragrunt.hcl
    │   └── env.json                # QA environment overrides
    └── prod/
        ├── terragrunt.hcl
        └── env.json                # Prod environment overrides
```

---

## State Management Architecture

This repository supports **dual CI/CD pipelines** with different state backends:

| CI/CD Platform | Tool | State Backend | When to Use |
|---|---|---|---|
| **GitHub Actions** | Terragrunt | AWS S3 (auto-created by Terragrunt) | GitHub pipelines |
| **GitLab CI/CD** | Terraform | GitLab Remote State (HTTP backend) | GitLab pipelines |

### Backend Configuration

- **`infra/src/backend.tf`** — HTTP backend (GitLab remote state). Used by `gitlab-terraform` commands in the GitLab pipeline. GitLab injects the backend URL and credentials automatically.
- **`infra/root.hcl`** — Terragrunt generates an S3 backend at runtime. Used by all GitHub Actions jobs. Terragrunt automatically creates the S3 bucket (`<stack>-<region>-<account-id>-tfstate`) and DynamoDB lock table if they don't exist.

> When running via **Terragrunt** (GitHub Actions), the generated `backend.tf` overrides the HTTP backend with S3.
> When running via **Terraform directly** (GitLab CI), the checked-in `backend.tf` HTTP backend stores state in GitLab.

---

## GitHub Actions Pipeline

Triggered on push/PR to `main`, `dev`, `qa`, and `release/*` branches.

| Branch | Environment Deployed |
|---|---|
| `dev` | `infra/environments/dev/` |
| `qa` | `infra/environments/qa/` |
| `main` / `release/*` | `infra/environments/prod/` |

**Required GitHub Secrets:**

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS access key for the deploying IAM role |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_DEFAULT_REGION` | Target AWS region (e.g. `us-east-1`) |

Workflows:
- [`.github/workflows/infra-deploy.yaml`](.github/workflows/infra-deploy.yaml) — Plan on PR, Apply on push
- [`.github/workflows/infra-destroy.yaml`](.github/workflows/infra-destroy.yaml) — Manual destroy (`workflow_dispatch`)

---

## GitLab CI/CD Pipeline

> **Note:** The GitLab CI file is named `gitlab-ci.yml` (not `.gitlab-ci.yml`) to prevent it from running in the template repository itself. ENBUILD renames it to `.gitlab-ci.yml` when generating a new repository from this template.

The pipeline uses `gitlab-terraform` and stores state in [GitLab-managed Terraform state](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html). Variables are passed via [`infra/src/tfvars.hcl`](infra/src/tfvars.hcl).

Stages: `init` → `validate` → `plan` → `deploy` → `destroy` (manual)

---

## Environments & Configuration

Three environments are pre-configured. The **base defaults** live in [`infra/default.json`](infra/default.json) and each environment can override any value in its own `env.json`:

| File | Purpose |
|---|---|
| [`infra/default.json`](infra/default.json) | Shared defaults for all environments |
| [`infra/environments/dev/env.json`](infra/environments/dev/env.json) | Dev overrides (public endpoint enabled) |
| [`infra/environments/qa/env.json`](infra/environments/qa/env.json) | QA overrides (private endpoint, `desired_size: 2`) |
| [`infra/environments/prod/env.json`](infra/environments/prod/env.json) | Prod overrides |

Key configurable variables:

```jsonc
{
  "cluster_version": "1.32",          // EKS Kubernetes version
  "authentication_mode": "API",       // Access entries only (no aws-auth ConfigMap)
  "cluster_endpoint_public_access": false,
  "cluster_endpoint_private_access": true,
  "deletion_protection": false,
  "instance_types": ["t3.large"],
  "eks_node_groups_min_size": 1,
  "eks_node_groups_max_size": 5,
  "eks_node_groups_desired_size": 1,
  "enable_nat_gateway": true,
  "single_nat_gateway": true,
  "create_vpc": true,
  "vpc_cidr": "10.0.0.0/16"
}
```

### Bring Your Own VPC

To use an existing VPC instead of creating one, set in your `env.json`:

```json
{
  "create_vpc": false,
  "vpc_id": "vpc-xxxxxxxx",
  "subnet_ids": ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
}
```

### Iron Bank / registry1 Mirror (DoD / Air-gapped)

For environments without public internet access to `registry1.dso.mil`:

```json
{
  "create_registry1_mirror": true,
  "registry1_mirror_proxy_address": "http://<your-internal-proxy>:5000"
}
```

---

## Air-gapped / GovCloud Considerations

- All ARNs are dynamically constructed using `data.aws_partition.current` — compatible with `aws-us-gov` partition.
- Set `AWS_DEFAULT_REGION` to a GovCloud region (`us-gov-west-1` or `us-gov-east-1`).
- Verify EKS version availability in your GovCloud region before deploying: `aws eks describe-addon-versions --region us-gov-west-1`
- In fully air-gapped environments, mirror the Terraform modules via a private registry or use a local module path.

---

## Outputs

After a successful deploy:

```bash
# Configure kubectl
aws eks --region <region> update-kubeconfig --name <cluster-name>

# SOPS encryption config (for BigBang / secret management)
terraform output bigbang_sops_config
```
