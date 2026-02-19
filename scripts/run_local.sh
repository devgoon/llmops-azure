#!/usr/bin/env bash
set -euo pipefail

python -m venv .venv
source .venv/bin/activate
pip install -r backend/api/requirements.txt
uvicorn backend.api.main:app --reload --port 8000
