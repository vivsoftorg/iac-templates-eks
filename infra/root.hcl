locals {
  aws_region = get_env("AWS_DEFAULT_REGION", "us-east-1")
  stack      = get_env("STACK_NAME", format("%.11s", basename(dirname(replace(get_parent_terragrunt_dir(), "infra", "")))))
  stack_name = lower(replace(local.stack, "_", "-"))

  # Derive environment name from the relative path of the child config
  environment = replace(path_relative_to_include(), "environments/", "")

  # Read default and environment-specific inputs from JSON files.
  # Returns an empty map when the file is not present (e.g. in local/custom setups).
  default_vars = try(jsondecode(file(find_in_parent_folders("default.json", "default.json"))), {})
  env_vars     = try(jsondecode(file(find_in_parent_folders("env.json", "env.json"))), {})
}

# ---------------------------------------------------------------------------
# Remote state – S3 backend with DynamoDB state locking
# ---------------------------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "${local.stack_name}-${local.aws_region}-${get_aws_account_id()}-tfstate"
    key            = "infra/${local.environment}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "${local.stack_name}-${local.aws_region}-${get_aws_account_id()}-tfstate-lock"
  }
}

# ---------------------------------------------------------------------------
# Terraform CLI settings
# ---------------------------------------------------------------------------
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
  }
}

# ---------------------------------------------------------------------------
# Inputs – default values are overlaid by environment-specific overrides.
# Computed values (environment, region, cluster_name) are injected last so
# they cannot be accidentally overridden by the JSON files.
# ---------------------------------------------------------------------------
inputs = merge(
  local.default_vars,
  local.env_vars,
  {
    environment  = local.environment
    aws_region   = local.aws_region
    stack_name   = local.stack_name
    cluster_name = "${local.stack_name}-${local.environment}"
  }
)
