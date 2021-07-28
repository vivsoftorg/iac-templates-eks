locals {
  aws_region = get_env("AWS_DEFAULT_REGION")
  stack_name = get_env("STACK_NAME")
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "${local.stack_name}-${local.aws_region}"
    key    = "infra/eks/terraform.tfstate"
    region = local.aws_region
    encrypt = true
  }
}


terraform {
  source = "git::git@gitlab.com:enbuild-staging/terraform-modules/terraform-aws-eks.git?ref=v17.1.0"
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${get_terragrunt_dir()}/tfvars.json"
    ]
  }
}
