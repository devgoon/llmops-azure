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

    if ollama_base:
        # Ollama local API
        url = f"{ollama_base.rstrip('/')}/api/generate"
        payload = {
            "model": req.model or os.getenv("OLLAMA_MODEL", "llama3"),
            "prompt": req.prompt,
            "options": {"temperature": req.temperature or 0.2},
            "stream": False
        }
        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(url, json=payload)
            r.raise_for_status()
            data = r.json()
            return {"model": payload["model"], "output": data.get("response", r.text)}

    else:
        raise HTTPException(status_code=400, detail="Set OLLAMA_BASE_URL env var.")
