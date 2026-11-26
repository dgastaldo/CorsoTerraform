# Versione PowerShell di bootstrap-backend.sh
# Uso: $env:STUDENT = "dgast"; ./bootstrap-backend.ps1
$ErrorActionPreference = "Stop"
$student  = $env:STUDENT
$location = if ($env:LOCATION) { $env:LOCATION } else { "westeurope" }
$rg = "rg-tfstate-$student"
$sa = "sttfstate$student$(Get-Random -Minimum 1000 -Maximum 9999)"

az group create --name $rg --location $location --output none
#az storage account create --name $sa --resource-group $rg --location $location --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false --output none

$saId = az storage account show --name $sa --resource-group $rg --query id -o tsv
$me   = az ad signed-in-user show --query id -o tsv
az role assignment create --assignee-object-id $me --assignee-principal-type User --role "Storage Blob Data Contributor" --scope $saId --output none

Start-Sleep -Seconds 30
az storage container create --account-name $sa --name tfstate --auth-mode login --output none

@"
resource_group_name  = "$rg"
storage_account_name = "$sa"
container_name       = "tfstate"
key                  = "dvo05-$student.tfstate"
use_azuread_auth     = true
"@ | Set-Content -Path backend.hcl
Write-Host "Creato backend.hcl per lo storage account $sa"
