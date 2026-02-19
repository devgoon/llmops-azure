#!/usr/bin/env bash
set -euo pipefail

# Setup Azure OIDC for GitHub Actions.
# Requires: az login

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
RESOURCE_GROUP="${RESOURCE_GROUP:-}"
APP_NAME="${APP_NAME:-gha-llmops-azure}"
GITHUB_REPO="${GITHUB_REPO:-devgoon/llmops-azure}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
FED_NAME="${FED_NAME:-github-actions-main}"

if [[ -z "$SUBSCRIPTION_ID" || -z "$RESOURCE_GROUP" ]]; then
  echo "Missing SUBSCRIPTION_ID or RESOURCE_GROUP."
  echo "Set them in .env or export before running."
  exit 1
fi

TENANT_ID="$(az account show --query tenantId -o tsv)"
SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"

APP_ID="$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)"
if [[ -z "$APP_ID" || "$APP_ID" == "null" ]]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
fi

if ! az ad sp show --id "$APP_ID" >/dev/null 2>&1; then
  az ad sp create --id "$APP_ID" >/dev/null
fi

cat > /tmp/federated.json <<EOF
{
  "name": "${FED_NAME}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_REPO}:ref:refs/heads/${GITHUB_BRANCH}",
  "description": "OIDC for GitHub Actions on ${GITHUB_BRANCH}",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF

if ! az ad app federated-credential show --id "$APP_ID" --federated-credential-id "$FED_NAME" >/dev/null 2>&1; then
  az ad app federated-credential create \
    --id "$APP_ID" \
    --parameters /tmp/federated.json >/dev/null
fi

az role assignment create \
  --assignee "$APP_ID" \
  --role contributor \
  --scope "$SCOPE" >/dev/null

cat <<EOF
OIDC setup complete.

Add these GitHub Secrets:
- AZURE_CLIENT_ID=$APP_ID
- AZURE_TENANT_ID=$TENANT_ID
- AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
EOF
