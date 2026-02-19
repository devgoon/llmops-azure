TF_DIR := terraform
TFSTATE_RESOURCE_GROUP := my-llmops-rg
TFSTATE_STORAGE_ACCOUNT := tfllmops
TFSTATE_CONTAINER := tfstate
TFSTATE_KEY := llmops-azure.tfstate

.PHONY: terraform-init terraform-apply-infra terraform-apply-app deploy run-local

terraform-init:
	terraform -chdir=$(TF_DIR) init \
		-backend-config="resource_group_name=$(TFSTATE_RESOURCE_GROUP)" \
		-backend-config="storage_account_name=$(TFSTATE_STORAGE_ACCOUNT)" \
		-backend-config="container_name=$(TFSTATE_CONTAINER)" \
		-backend-config="key=$(TFSTATE_KEY)" \
		-backend-config="use_azuread_auth=true"

terraform-apply-infra: terraform-init
	terraform -chdir=$(TF_DIR) apply -auto-approve \
		-var "container_app_enabled=false"

terraform-apply-app: terraform-init
	terraform -chdir=$(TF_DIR) apply -auto-approve \
		-var "container_app_enabled=true" \
		-var "image_uri=$(IMAGE_URI)"

# Runs infra apply; build/push and app apply are handled by GitHub Actions.
deploy: terraform-apply-infra

run-local:
	./scripts/run_local.sh
