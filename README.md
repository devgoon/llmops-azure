# LLMOps – Azure + Standalone (Local‑First)


A **minimal, low‑cost LLMOps starter** you can run 100% on your laptop. It favors:

- Local dev with **Ollama** (CPU-friendly)
- **ChromaDB** for local vector search (RAG)
- **FastAPI** service you can run locally
- **MLflow** for experiment tracking (local file store)

> Goal: learn and ship LLM apps without cloud costs or complexity.

---

## ✨ Features

- **Local‑only** development (no cloud required)
- **Ollama** local model serving (simple, CPU-friendly)
- **RAG‑ready** app scaffold (slots to add Chroma/embeddings)
- **Experiment tracking** with MLflow (file store by default)

---

## 🗂️ Repo Layout

```
./
├─ backend/
│  ├─ api/
│  │  ├─ main.py            # FastAPI service (with MLflow logging)
│  │  └─ requirements.txt
│  └─ tests/
├─ mlops/
│  ├─ track_example.py      # MLflow example run
│  ├─ analyze_metrics.py    # Metrics analysis & comparison tool
│  └─ requirements.txt
├─ scripts/
│  ├─ run_local.sh          # Start FastAPI locally
│  ├─ create_test_chats.sh  # Generate test requests for benchmarking
│  └─ set_env_example.sh    # Example env vars
├─ docker/
│  └─ Dockerfile            # Container for backend/api
├─ docker/
│  └─ Dockerfile            # Container for backend/api
├─ Makefile                 # Task automation (start-all, analyze, etc.)
├─ .env.local.example       # Local app config template
├─ .gitignore
├─ LICENSE
└─ README.md
```

---

## 🧰 Prereqs

- **Python 3.11+**, **pip**
- **Docker** (optional, for container runs)
- **Ollama** (quickest start, CPU-friendly)

---

## 🚀 Quick Start (Local)

### Fastest way (one command):
```bash
make start-all
```

This will:
1. Start the FastAPI service
2. Launch MLflow UI
3. Generate 5 test chats with varying temperature settings
4. Display metrics analysis (latency, throughput, tokens)
5. Show you the dashboard & API links

### Step-by-step setup (if you prefer):

1) **Create a virtual env** and install dependencies:
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r backend/api/requirements.txt
```

2) **(Optional) Start Ollama** on your machine and pull a model:
```bash
# Install Ollama per official docs, then:
ollama pull llama3
```

3) **Create local env file**:
```bash
cp .env.local.example .env.local
```

4) **Run the API**:
```bash
make run-local
```

5) **Test the service**:
```bash
curl -s -X POST http://127.0.0.1:8000/chat \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"Explain retrieval-augmented generation"}' | jq
```

The API expects `OLLAMA_BASE_URL` to be set (defaults to `http://localhost:11434`).

---

## 🏃 Make Targets (Auto-tasks)

| Target | Purpose |
|--------|---------|
| `make start-all` | **Run everything**: API + MLflow + test chats + analysis |
| `make run-local` | Start just the FastAPI service |
| `make test-chats` | Generate 5 test requests (different temperatures) |
| `make analyze` | Show metrics analysis (latency, throughput, tokens/sec) |
| `make mlflow-ui` | Browse MLflow experiments at http://127.0.0.1:5000 |

---

## 🧪 Metrics & Experiment Tracking (MLflow)

### API Metrics Logging

The FastAPI service automatically logs detailed metrics to MLflow when `MLFLOW_ENABLED=1`:

**Logged Metrics (per request):**
- `latency_ms` — Response time in milliseconds
- `latency_sec` — Response time in seconds (for averaging)
- `input_tokens` — Approximate tokens in the prompt
- `output_tokens` — Approximate tokens in the response
- `total_tokens` — Combined input + output
- `tokens_per_second` — Generation throughput (efficiency metric)
- `success` — 1 for success, 0 for error

**Logged Parameters:**
- `temperature` — Randomness setting (0.0–1.0)
- `model` — Model name (e.g., `llama3`)
- `prompt_length` — Character count of input

### Analyze Metrics

After running test chats, view comprehensive metrics:
```bash
make analyze
```

This shows:
- **Run Summary** — Each request's latency, tokens, throughput
- **Temperature Impact** — How temperature affects response quality/speed
- **Aggregate Statistics** — Mean, median, min, max across all runs
- **CSV Export** — `mlruns/runs_export.csv` for custom analysis

### Browse Experiments

View all runs in an interactive dashboard:
```bash
make mlflow-ui
```
Then open **http://127.0.0.1:5000** to compare experiments.

### Custom Experiment Tracking

Use the example script to log your own runs:
```bash
python mlops/track_example.py
```

Artifacts and metadata go into `./mlruns/` by default. To use remote MLflow, set `MLFLOW_TRACKING_URI` and `MLFLOW_ARTIFACT_URI` (e.g., Azure Blob).

---





---

## 🧩 Next Steps

### Performance Tuning
- Use `make analyze` to identify bottlenecks (latency, throughput)
- Compare temperatures via the **Temperature Impact** analysis
- Export metrics to CSV (`mlruns/runs_export.csv`) for custom analysis
- Monitor `tokens_per_second` to optimize for inference speed vs cost

### Feature Development
- Add embeddings + ChromaDB calls to `backend/api/main.py` for RAG demo
- Integrate vector search into `/chat` endpoint
- Add cost estimation metrics (tokens × price per model)
- Compare different Ollama models (mistral, neural-chat, etc.)

---
## ⚙️ Environment Configuration

### `.env.local` — Local App Runtime
For running the API locally. Includes:
- `OLLAMA_BASE_URL` — Ollama server address
- `OLLAMA_MODEL` — Model to use (default: `llama3`)
- `APP_HOST` / `APP_PORT` — API binding
- `MLFLOW_ENABLED` — Enable/disable metric logging (0 or 1)

Start from `.env.local.example`:
```bash
cp .env.local.example .env.local
```

This file is Git-ignored for security.

---

PRs welcome. MIT licensed.