# Deploy to Azure Container Apps (CPU, low-cost)

This guide deploys the FastAPI service to **Azure Container Apps** (ACA) using a tiny CPU plan that can scale to zero.

> Prereqs: Azure CLI (`az`), Docker, an Azure subscription, and a resource group.

## 1) Build and push the image

Choose one registry path:
- **Azure Container Registry (ACR)** — recommended for private images
- **GitHub Container Registry (GHCR)** — quick if your GitHub is set up

### ACR (recommended)
```bash
# variables
RG=my-llmops-rg
LOC=eastus
ACR_NAME=myllmopsacr$RANDOM
IMAGE_TAG=v0.1.0
APP_IMAGE=${ACR_NAME}.azurecr.io/llmops-api:${IMAGE_TAG}

# create rg + acr
az group create -n $RG -l $LOC
az acr create -n $ACR_NAME -g $RG --sku Basic
az acr login -n $ACR_NAME

# build + push
docker build -t $APP_IMAGE -f docker/Dockerfile .
docker push $APP_IMAGE
```

### GHCR (alternative)
```bash
IMAGE_TAG=v0.1.0
APP_IMAGE=ghcr.io/<your-gh-handle>/llmops-api:${IMAGE_TAG}

docker build -t $APP_IMAGE -f docker/Dockerfile .
docker push $APP_IMAGE
```

## 2) Create Container Apps environment + app
```bash
ENV_NAME=llmops-env
APP_NAME=llmops-api

# Create a Container Apps env (consumption, cheap)
az containerapp env create \
  -g $RG -n $ENV_NAME -l $LOC

# Deploy the app (CPU x .25, 0.5Gi) and scale to zero when idle
az containerapp create \
  -g $RG -n $APP_NAME \
  --image $APP_IMAGE \
  --environment $ENV_NAME \
  --ingress external --target-port 8000 \
  --min-replicas 0 --max-replicas 1 \
  --cpu 0.25 --memory 0.5Gi \
  --env-vars OLLAMA_BASE_URL=  # leave empty unless you route to an external LLM

# Get the FQDN
az containerapp show -g $RG -n $APP_NAME --query properties.configuration.ingress.fqdn -o tsv
```

You can now hit `https://<fqdn>/health` and `/chat`.

## 3) Optional: ACA Jobs for on‑demand GPU work

Create a Job that uses a GPU SKU, and only run it when needed. You pay only while it runs.

(See Azure docs for `az containerapp job` with `--gpu`.)
