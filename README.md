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

## EBS CSI Driver

The EBS CSI driver is configured to use **EKS Pod Identity** for IAM credentials. This allows the driver to function in private subnets without relying on EC2 Instance Metadata Service (IMDS).

---

## Cluster Access

The deploying user's IAM identity is automatically granted cluster admin access via EKS Access Entries. After deployment, run:

```bash
aws eks --region <region> update-kubeconfig --name <cluster-name>
kubectl get nodes
```

Additional access entries can be configured via the `access_entries` variable in environment config.

---

## Outputs

After a successful deploy:

```bash
# Configure kubectl
aws eks --region <region> update-kubeconfig --name <cluster-name>

# SOPS encryption config (for BigBang / secret management)
terraform output bigbang_sops_config
```
