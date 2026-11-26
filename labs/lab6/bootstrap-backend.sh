#!/usr/bin/env bash
# Crea resource group, storage account e container per lo state remoto.
# Uso: STUDENT=mrossi ./bootstrap-backend.sh   (Cloud Shell o Git Bash)
set -euo pipefail

STUDENT="${STUDENT:?imposta STUDENT}"
LOCATION="${LOCATION:-westeurope}"
RG="rg-tfstate-${STUDENT}"
SA="sttfstate${STUDENT}$((RANDOM % 9000 + 1000))"

az group create --name "$RG" --location "$LOCATION" --output none
az storage account create \
  --name "$SA" --resource-group "$RG" --location "$LOCATION" \
  --sku Standard_LRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false --output none

SA_ID=$(az storage account show --name "$SA" --resource-group "$RG" --query id -o tsv)
ME=$(az ad signed-in-user show --query id -o tsv)
az role assignment create --assignee-object-id "$ME" \
  --assignee-principal-type User \
  --role "Storage Blob Data Contributor" --scope "$SA_ID" --output none

# i role assignment possono impiegare qualche minuto a propagarsi
sleep 30
az storage container create --account-name "$SA" --name tfstate --auth-mode login --output none

cat > backend.hcl <<HCL
resource_group_name  = "$RG"
storage_account_name = "$SA"
container_name       = "tfstate"
key                  = "dvo05-${STUDENT}.tfstate"
use_azuread_auth     = true
HCL
echo "Creato backend.hcl per lo storage account $SA"
