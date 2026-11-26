# Configurazione parziale: i valori arrivano da backend.hcl
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {}
}
