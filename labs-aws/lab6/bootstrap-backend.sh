#!/usr/bin/env bash
# Crea il bucket S3 per lo state remoto e scrive backend.hcl.
# Uso: STUDENT=mrossi ./bootstrap-backend.sh   (CloudShell o Git Bash, con aws CLI configurata)
set -euo pipefail

STUDENT="${STUDENT:?imposta STUDENT}"
REGION="${AWS_REGION:-eu-west-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="tfstate-${STUDENT}-${ACCOUNT_ID}"

if [ "$REGION" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" >/dev/null
else
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
    --create-bucket-configuration "LocationConstraint=$REGION" >/dev/null
fi

aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
# la cifratura SSE-S3 (AES256) è già attiva di default su ogni nuovo bucket

cat > backend.hcl <<HCL
bucket       = "$BUCKET"
key          = "dvo05-${STUDENT}.tfstate"
region       = "$REGION"
encrypt      = true
use_lockfile = true
HCL
echo "Creato backend.hcl per il bucket $BUCKET"
