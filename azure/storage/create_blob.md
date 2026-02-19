# Create Azure Blob Storage for artifacts (cheap)

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
