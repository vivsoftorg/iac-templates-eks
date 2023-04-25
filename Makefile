SHELL := /bin/bash # Use bash syntax
BRANCH := $(shell ./scripts/get_git_branch.sh)
ENVIRONMENT ?= $(BRANCH) # Set the ENVIRONMENT Variable only if its not set already



default: fmt

fmt:
	terraform fmt infra/src/
	terragrunt hclfmt infra/

set_env:
	./scripts/set_env.sh .envrc

init: set_env
	source .envrc && terragrunt init --terragrunt-working-dir infra/environments/${ENVIRONMENT}/

plan: init
	source .envrc && terragrunt plan --terragrunt-working-dir infra/environments/${ENVIRONMENT}/

apply: init
	source .envrc && terragrunt apply -auto-approve --terragrunt-working-dir infra/environments/${ENVIRONMENT}/

output:
	source .envrc && terragrunt output --terragrunt-working-dir infra/environments/${ENVIRONMENT}/

destroy:
	source .envrc && terragrunt destroy -auto-approve --terragrunt-working-dir infra/environments/${ENVIRONMENT}/

build-push-image:
	source .envrc && ./scripts/build_image.sh ${ENVIRONMENT}

deploy:
	source .envrc && terragrunt run-all apply --terragrunt-non-interactive