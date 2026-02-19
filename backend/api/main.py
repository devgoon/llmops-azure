from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import time
import httpx

app = FastAPI(title="LLMOps Azure + Standalone API", version="0.1.0")

class ChatRequest(BaseModel):
    prompt: str
    model: str | None = None
    temperature: float | None = 0.2


def _mlflow_enabled() -> bool:
    return os.getenv("MLFLOW_ENABLED", "").lower() in {"1", "true", "yes"}


def _log_mlflow(params: dict, metrics: dict) -> None:
    if not _mlflow_enabled():
        return
    try:
        import mlflow
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"MLflow not available: {exc}")

    mlflow.set_experiment(os.getenv("MLFLOW_EXPERIMENT", "llmops-api"))
    with mlflow.start_run(run_name="chat-request"):
        for key, value in params.items():
            mlflow.log_param(key, value)
        for key, value in metrics.items():
            mlflow.log_metric(key, value)

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/chat")
async def chat(req: ChatRequest):
    ollama_base = os.getenv("OLLAMA_BASE_URL")
    start_time = time.time()

    if ollama_base:
        # Ollama local API
        url = f"{ollama_base.rstrip('/')}/api/generate"
        payload = {
            "model": req.model or os.getenv("OLLAMA_MODEL", "llama3"),
            "prompt": req.prompt,
            "options": {"temperature": req.temperature or 0.2},
            "stream": False
        }
        try:
            async with httpx.AsyncClient(timeout=120) as client:
                r = await client.post(url, json=payload)
                r.raise_for_status()
                data = r.json()
        except Exception as exc:
            _log_mlflow(
                {
                    "backend": "ollama",
                    "model": payload["model"],
                    "temperature": payload["options"]["temperature"],
                    "prompt_length": len(req.prompt),
                },
                {
                    "latency_ms": (time.time() - start_time) * 1000,
                    "success": 0,
                },
            )
            raise HTTPException(status_code=500, detail=str(exc))

        _log_mlflow(
            {
                "backend": "ollama",
                "model": payload["model"],
                "temperature": payload["options"]["temperature"],
                "prompt_length": len(req.prompt),
            },
            {
                "latency_ms": (time.time() - start_time) * 1000,
                "success": 1,
            },
        )
        return {"model": payload["model"], "output": data.get("response", r.text)}

    else:
        raise HTTPException(status_code=400, detail="Set OLLAMA_BASE_URL env var.")
