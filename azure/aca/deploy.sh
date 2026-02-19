#!/usr/bin/env bash
set -euo pipefail

RG=${RG:-my-llmops-rg}
LOC=${LOC:-eastus}
ENV_NAME=${ENV_NAME:-llmops-env}
ACR_NAME=${ACR_NAME:-myllmopsacr$RANDOM}
IMAGE_TAG=${IMAGE_TAG:-v0.1.0}
APP_NAME=${APP_NAME:-llmops-api}
APP_IMAGE=${APP_IMAGE:-${ACR_NAME}.azurecr.io/llmops-api:${IMAGE_TAG}}

# Resource Group & ACR
az group create -n "$RG" -l "$LOC"
az acr create -n "$ACR_NAME" -g "$RG" --sku Basic
az acr login -n "$ACR_NAME"

# Build & push image
docker build -t "$APP_IMAGE" -f docker/Dockerfile .
docker push "$APP_IMAGE"

# Container Apps env
az containerapp env create -g "$RG" -n "$ENV_NAME" -l "$LOC"

# App (scale-to-zero)
az containerapp create \
  -g "$RG" -n "$APP_NAME" \
  --image "$APP_IMAGE" \
  --environment "$ENV_NAME" \
  --ingress external --target-port 8000 \
  --min-replicas 0 --max-replicas 1 \
  --cpu 0.25 --memory 0.5Gi

az containerapp show -g "$RG" -n "$APP_NAME" \
  --query properties.configuration.ingress.fqdn -o tsv
