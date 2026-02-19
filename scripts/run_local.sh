#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck source=/dev/null
	source "$ENV_FILE"
	set +a
fi

if [[ -z "${OLLAMA_BASE_URL:-}" ]]; then
	echo "OLLAMA_BASE_URL is not set. Add it to .env or export it before running."
	exit 1
fi

if ! curl -fsS "${OLLAMA_BASE_URL%/}/api/tags" >/dev/null 2>&1; then
	if ! command -v ollama >/dev/null 2>&1; then
		echo "Ollama is not reachable at $OLLAMA_BASE_URL and 'ollama' is not on PATH."
		exit 1
	fi

	echo "Starting Ollama..."
	nohup ollama serve >/tmp/ollama.log 2>&1 &

	for _ in {1..20}; do
		if curl -fsS "${OLLAMA_BASE_URL%/}/api/tags" >/dev/null 2>&1; then
			break
		fi
		sleep 0.5
	done

	if ! curl -fsS "${OLLAMA_BASE_URL%/}/api/tags" >/dev/null 2>&1; then
		echo "Ollama failed to start. Check /tmp/ollama.log."
		exit 1
	fi
fi

python -m venv .venv
source .venv/bin/activate
pip install -r backend/api/requirements.txt
uvicorn backend.api.main:app --reload --port 8000
