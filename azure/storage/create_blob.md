# Create Azure Blob Storage for artifacts (cheap)

If you want an automated setup (providers + tfstate storage + OIDC), use `./scripts/bootstrap_azure.sh` instead of the manual steps below.

```bash
RG=my-llmops-rg
LOC=eastus
STOR=llmopsstor$RANDOM

az group create -n $RG -l $LOC
az storage account create -g $RG -n $STOR -l $LOC --sku Standard_LRS

# Create a container for artifacts
CONTAINER=artifacts
az storage container create --account-name $STOR --name $CONTAINER --auth-mode login

# Show connection info (use with MLflow or your app)
az storage account show-connection-string -g $RG -n $STOR -o tsv
```

Blob (Hot tier) costs fractions of a dollar per GB per month for personal use.
