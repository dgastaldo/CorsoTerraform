# Crea il bucket S3 per lo state remoto e scrive backend.hcl.
# Uso: $env:STUDENT = "mrossi"; ./bootstrap-backend.ps1   (aws CLI configurata)
$ErrorActionPreference = "Stop"

if (-not $env:STUDENT) { throw "imposta `$env:STUDENT" }
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "eu-west-1" }
$AccountId = aws sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0) { throw "aws CLI non configurata (aws sts get-caller-identity)" }
$Bucket = "tfstate-$($env:STUDENT)-$AccountId"

if ($Region -eq "us-east-1") {
    aws s3api create-bucket --bucket $Bucket --region $Region | Out-Null
} else {
    aws s3api create-bucket --bucket $Bucket --region $Region `
        --create-bucket-configuration "LocationConstraint=$Region" | Out-Null
}
if ($LASTEXITCODE -ne 0) { throw "creazione bucket fallita" }

aws s3api put-bucket-versioning --bucket $Bucket --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket $Bucket `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
# la cifratura SSE-S3 (AES256) è già attiva di default su ogni nuovo bucket

@"
bucket       = "$Bucket"
key          = "dvo05-$($env:STUDENT).tfstate"
region       = "$Region"
encrypt      = true
use_lockfile = true
"@ | Set-Content -Path backend.hcl -Encoding ascii
Write-Host "Creato backend.hcl per il bucket $Bucket"
