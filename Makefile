TF_DIR := terraform
TFSTATE_RESOURCE_GROUP := my-llmops-rg
TFSTATE_STORAGE_ACCOUNT := tfllmops
TFSTATE_CONTAINER := tfstate
TFSTATE_KEY := llmops-azure.tfstate

.PHONY: terraform-init terraform-apply-infra terraform-apply-app deploy run-local mlflow-ui test-chats start-all analyze

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

mlflow-ui:
	mlflow ui --host 127.0.0.1 --port 5000

test-chats:
	./scripts/create_test_chats.sh

start-all:
	@echo "🚀 Starting LLMOps stack..."
	@echo ""
	@./scripts/run_local.sh > /tmp/api.log 2>&1 &
	@sleep 4
	@echo "✅ API running on http://127.0.0.1:8000"
	@mlflow ui --host 127.0.0.1 --port 5000 > /tmp/mlflow.log 2>&1 &
	@sleep 2
	@echo "✅ MLflow running on http://127.0.0.1:5000"
	@echo ""
	@echo "📝 Creating test chats..."
	@./scripts/create_test_chats.sh
	@echo ""
	@echo "✅ Everything is ready!"
	@echo ""
	@echo "📊 Dashboard: http://127.0.0.1:5000"
	@echo "🧪 API: http://127.0.0.1:8000/docs (Swagger UI)"
	@echo ""
	@echo "💡 Tip: View logs with 'tail -f /tmp/api.log' or 'tail -f /tmp/mlflow.log'"

analyze:
	. .venv/bin/activate && python mlops/analyze_metrics.py
