#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.bootstrap"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
RESOURCE_GROUP="${RESOURCE_GROUP:-my-llmops-rg}"
LOCATION="${LOCATION:-eastus}"
TFSTATE_STORAGE_ACCOUNT="${TFSTATE_STORAGE_ACCOUNT:-tfllmops}"
TFSTATE_CONTAINER="${TFSTATE_CONTAINER:-tfstate}"
APP_NAME="${APP_NAME:-gha-llmops-azure}"
GITHUB_REPO="${GITHUB_REPO:-devgoon/llmops-azure}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
FED_NAME="${FED_NAME:-github-actions-main}"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "Missing SUBSCRIPTION_ID. Set it in .env.bootstrap or export before running."
  exit 1
fi

az account set --subscription "$SUBSCRIPTION_ID"

APP_STATE=$(az provider show --namespace Microsoft.App --query registrationState -o tsv)
if [[ "$APP_STATE" != "Registered" ]]; then
  echo "Registering Microsoft.App provider..."
  az provider register --namespace Microsoft.App --wait
fi

OI_STATE=$(az provider show --namespace Microsoft.OperationalInsights --query registrationState -o tsv)
if [[ "$OI_STATE" != "Registered" ]]; then
  echo "Registering Microsoft.OperationalInsights provider..."
  az provider register --namespace Microsoft.OperationalInsights --wait
fi

if ! az group show -n "$RESOURCE_GROUP" &>/dev/null; then
  az group create -n "$RESOURCE_GROUP" -l "$LOCATION" >/dev/null
fi

if ! az storage account show -n "$TFSTATE_STORAGE_ACCOUNT" &>/dev/null; then
  az storage account create \
    -g "$RESOURCE_GROUP" \
    -n "$TFSTATE_STORAGE_ACCOUNT" \
    -l "$LOCATION" \
    --sku Standard_LRS >/dev/null
fi

az storage container create \
  --account-name "$TFSTATE_STORAGE_ACCOUNT" \
  --name "$TFSTATE_CONTAINER" \
  --auth-mode login >/dev/null

SUBSCRIPTION_ID="$SUBSCRIPTION_ID" \
RESOURCE_GROUP="$RESOURCE_GROUP" \
APP_NAME="$APP_NAME" \
GITHUB_REPO="$GITHUB_REPO" \
GITHUB_BRANCH="$GITHUB_BRANCH" \
FED_NAME="$FED_NAME" \
  "$SCRIPT_DIR/setup_oidc.sh" >/dev/null

APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
STORAGE_SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$TFSTATE_STORAGE_ACCOUNT"

HAS_ROLE=$(az role assignment list \
  --assignee "$APP_ID" \
  --scope "$STORAGE_SCOPE" \
  --query "[?roleDefinitionName=='Storage Blob Data Contributor'] | length(@)" \
  -o tsv)

if [[ "$HAS_ROLE" == "0" ]]; then
  az role assignment create \
    --assignee "$APP_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$STORAGE_SCOPE" >/dev/null
fi

TENANT_ID=$(az account show --query tenantId -o tsv)

cat <<EOF
Bootstrap complete.

GitHub Secrets:
- AZURE_CLIENT_ID=$APP_ID
- AZURE_TENANT_ID=$TENANT_ID
- AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID

TF state:
- Storage account: $TFSTATE_STORAGE_ACCOUNT
- Container: $TFSTATE_CONTAINER
EOF
