
.PHONY: run-local mlflow-ui test-chats start-all analyze

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
	@echo "📊 Analyzing metrics..."
	@make analyze
	@echo ""
	@echo "✅ Everything is ready!"
	@echo ""
	@echo "📊 Dashboard: http://127.0.0.1:5000"
	@echo "🧪 API: http://127.0.0.1:8000/docs (Swagger UI)"
	@echo ""
	@echo "💡 Tip: View logs with 'tail -f /tmp/api.log' or 'tail -f /tmp/mlflow.log'"

analyze:
	. .venv/bin/activate && python mlops/analyze_metrics.py

analyze:
	. .venv/bin/activate && python mlops/analyze_metrics.py
