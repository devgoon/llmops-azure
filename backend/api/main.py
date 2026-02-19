from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import time
import httpx
import re

app = FastAPI(title="LLMOps Azure + Standalone API", version="0.1.0")

class ChatRequest(BaseModel):
    prompt: str
    model: str | None = None
    temperature: float | None = 0.2


def _mlflow_enabled() -> bool:
    return os.getenv("MLFLOW_ENABLED", "").lower() in {"1", "true", "yes"}


def _count_tokens(text: str) -> int:
    """Rough token count: split by spaces/punctuation."""
    return len(re.findall(r'\b\w+\b', text))


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
    input_tokens = _count_tokens(req.prompt)

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
            elapsed = time.time() - start_time
            _log_mlflow(
                {
                    "backend": "ollama",
                    "model": payload["model"],
                    "temperature": payload["options"]["temperature"],
                    "prompt_length": len(req.prompt),
                    "input_tokens": input_tokens,
                },
                {
                    "latency_ms": elapsed * 1000,
                    "latency_sec": elapsed,
                    "success": 0,
                    "input_tokens": input_tokens,
                    "output_tokens": 0,
                    "total_tokens": input_tokens,
                },
            )
            raise HTTPException(status_code=500, detail=str(exc))

        output_text = data.get("response", "")
        output_tokens = _count_tokens(output_text)
        elapsed = time.time() - start_time
        
        _log_mlflow(
            {
                "backend": "ollama",
                "model": payload["model"],
                "temperature": payload["options"]["temperature"],
                "prompt_length": len(req.prompt),
                "input_tokens": input_tokens,
            },
            {
                "latency_ms": elapsed * 1000,
                "latency_sec": elapsed,
                "success": 1,
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "total_tokens": input_tokens + output_tokens,
                "tokens_per_second": output_tokens / elapsed if elapsed > 0 else 0,
            },
        )
        return {"model": payload["model"], "output": output_text}

    else:
        raise HTTPException(status_code=400, detail="Set OLLAMA_BASE_URL env var.")
