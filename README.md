# AWS EKS

This is the ENBUILD EKS catalog to deploy an Amazon EKS cluster utilizing the version "20.8.5" of the [official EKS module by Terraform AWS]((https://github.com/terraform-aws-modules/terraform-aws-eks).

```
  // source  = "terraform-aws-modules/eks/aws"
  // version = "20.24.3"

```

For environments without internet access, we have ensured that the entire module codebase is pre-downloaded and maintained in a local repository. This approach supports deployment in air-gapped environments by using the locally stored module version.

# Minimum IAM Policy for EKS Deployment

To facilitate the creation of the EKS cluster, please refer to the [min-iam-policy.json](./min-iam-policy.json) file. This file contains the minimal IAM policy required to successfully deploy the EKS cluster using Terraform. Ensure that the IAM roles or users deploying the cluster have permissions as specified in this file to avoid deployment issues.

# This is a common Catalog that is used for both Gitlab and Github.

# Github based deployment
For Github based deployment, we store the remote state in AWS S3 bucket. 
The deployment is driven by [github action](.github/workflows/infra-deploy.yaml) which uses `terrgrunt` to deploy the stack.

Since its based on `terragrunt` it supports the multiple environment. 

We have predefined 3 environments for the deployment

```
    dev (infra/environments/dev/)
    qa ( infra/environments/qa/)
    prod (infra/environments/prod/)
```

and the base source for all deployment is located at [infra/src](infra/src/) folder.

The default variables for all 3 deployents is present at [infra/default.hcl](infra/default.hcl) but you can override them on per environment basis. Using the files 
- [infra/environments/dev/env.hcl](infra/environments/dev/env.hcl) for Dev
- [infra/environments/qa/env.hcl](infra/environments/qa/env.hcl) for QA
- [infra/environments/prod/env.hcl](infra/environments/prod/env.hcl) for QA


# Gitlab based deployment
For Gitlab based deployment, we store the remove state to [GitLab-managed Terraform state](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html)

This is driven by the [Gitlab CI file](gitlab-ci.yml)

:note Please make a note , since this is a Gitlab template and we do not want to run the CI pipeline in the template, but rather the repositroy created using this template, the CI template file name is not `.gitlab-ci.yml`.  
ENBUILD after creating the repository from this template moves the file to proper name.

The [Gitlab CI file](gitlab-ci.yml) deploys the infrastrcutre using the `terraform` , and the source code is present at 
[infra/src/](infra/src/)
