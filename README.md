# AWS EKS

This documentation pertains to the deployment of an Amazon EKS cluster utilizing the version "20.8.5" of the [official EKS module by Terraform AWS]((https://github.com/terraform-aws-modules/terraform-aws-eks).

```
  // source  = "terraform-aws-modules/eks/aws"
  // version = "20.8.5"

```

For environments without internet access, we have ensured that the entire module codebase is pre-downloaded and maintained in a local repository. This approach supports deployment in air-gapped environments by using the locally stored module version.

# Minimum IAM Policy for EKS Deployment

To facilitate the creation of the EKS cluster, please refer to the [min-iam-policy.json](./min-iam-policy.json) file. This file contains the minimal IAM policy required to successfully deploy the EKS cluster using Terraform. Ensure that the IAM roles or users deploying the cluster have permissions as specified in this file to avoid deployment issues.
