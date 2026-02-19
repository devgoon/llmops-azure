from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os, httpx

app = FastAPI(title="LLMOps Azure + Standalone API", version="0.1.0")

class ChatRequest(BaseModel):
    prompt: str
    model: str | None = None
    temperature: float | None = 0.2

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/chat")
async def chat(req: ChatRequest):
    ollama_base = os.getenv("OLLAMA_BASE_URL")
    vllm_base = os.getenv("VLLM_OPENAI_BASE_URL")
    vllm_key  = os.getenv("VLLM_API_KEY", "EMPTY")

    if ollama_base:
        # Ollama local API
        url = f"{ollama_base.rstrip('/')}/api/generate"
        payload = {
            "model": req.model or os.getenv("OLLAMA_MODEL", "llama3"),
            "prompt": req.prompt,
            "options": {"temperature": req.temperature or 0.2}
        }
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(url, json=payload)
            r.raise_for_status()
            # Ollama streams lines; we return the final accumulated response
            text = ""
            for line in r.text.splitlines():
                try:
                    obj = httpx.Response(200, json=None)
                except Exception:
                    pass
            # Simpler: call /api/generate with stream=false by env if supported; else parse
            return {"model": payload["model"], "output": r.text}

    elif vllm_base:
        # vLLM OpenAI-compatible
        url = f"{vllm_base.rstrip('/')}/v1/chat/completions"
        payload = {
            "model": req.model or os.getenv("VLLM_MODEL", "meta-llama/Llama-3-8B-Instruct"),
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": req.prompt}
            ],
            "temperature": req.temperature or 0.2,
            "stream": False
        }
        headers = {"Authorization": f"Bearer {vllm_key}"}
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(url, headers=headers, json=payload)
            if r.status_code >= 400:
                raise HTTPException(status_code=r.status_code, detail=r.text)
            data = r.json()
            text = data.get("choices", [{}])[0].get("message", {}).get("content", "")
            return {"model": payload["model"], "output": text}

    else:
        raise HTTPException(status_code=400, detail="Set OLLAMA_BASE_URL or VLLM_OPENAI_BASE_URL env var.")
