SHELL := /bin/bash # Use bash syntax
BRANCH     := $(shell ./scripts/get_git_branch.sh | xargs)
ENVIRONMENT ?= $(strip $(BRANCH)) # Set the ENVIRONMENT variable only if it's not already set

# Use STACK_NAME env variable if set, otherwise derive from the current directory name
STACK_NAME ?= $(shell echo $${STACK_NAME:-$$(basename $(CURDIR))})

# # S3 backend coordinates (Terragrunt auto-creates these from root.hcl — override only if needed)
# TF_KEY          := infra/$(strip $(ENVIRONMENT))/terraform.tfstate
# S3_BUCKET       ?= $(STACK_NAME)-$(AWS_DEFAULT_REGION)-tfstate
# DYNAMODB_TABLE  ?= $(STACK_NAME)-$(AWS_DEFAULT_REGION)-tfstate-lock

default: fmt

fmt:
	terraform fmt infra/src/
	terragrunt hclfmt infra/

set_env:
	./scripts/set_env.sh .envrc

# Terragrunt auto-creates the S3 bucket and DynamoDB lock table via root.hcl.
# This target ensures AWS credentials are set before any remote operations.
create_backend: set_env

init: create_backend
	cd infra/environments/$(ENVIRONMENT) && source $(CURDIR)/.envrc && terragrunt init -reconfigure

plan: init
	cd infra/environments/$(ENVIRONMENT) && source $(CURDIR)/.envrc && terragrunt plan

apply: init
	cd infra/environments/$(ENVIRONMENT) && source $(CURDIR)/.envrc && terragrunt apply -auto-approve

output: apply
	cd infra/environments/$(ENVIRONMENT) && source $(CURDIR)/.envrc && terragrunt output

destroy: init
	cd infra/environments/$(ENVIRONMENT) && source $(CURDIR)/.envrc && terragrunt destroy -auto-approve

# Empties and removes the Terraform state bucket — use with extreme caution.
delete_backend: destroy
	source .envrc && aws s3 rb s3://$(S3_BUCKET) --force && \
	aws dynamodb delete-table --table-name $(DYNAMODB_TABLE) --region $(AWS_DEFAULT_REGION)

deploy:
	source .envrc && terragrunt run-all apply --terragrunt-non-interactive
