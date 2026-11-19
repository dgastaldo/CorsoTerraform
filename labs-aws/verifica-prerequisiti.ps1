# Verifica i prerequisiti tecnici per i laboratori DVO05 su AWS (solo letture, non crea nulla).
# Uso:  ./verifica-prerequisiti.ps1            (regione: AWS_REGION, altrimenti quella di aws configure, altrimenti eu-west-1)
#       ./verifica-prerequisiti.ps1 -Region eu-central-1
param(
    [string]$Region = "",
    [string]$InstanceType = "t3.micro"
)

$ok = 0; $warn = 0; $err = 0
function Ok($m)   { Write-Host "[OK]          $m" -ForegroundColor Green;  $script:ok++ }
function Warn($m) { Write-Host "[ATTENZIONE]  $m" -ForegroundColor Yellow; $script:warn++ }
function Err($m)  { Write-Host "[ERRORE]      $m" -ForegroundColor Red;    $script:err++ }

$awsCmd = Get-Command aws -ErrorAction SilentlyContinue
if (-not $Region) { $Region = $env:AWS_REGION }
if (-not $Region) { $Region = $env:AWS_DEFAULT_REGION }
if (-not $Region -and $awsCmd) { $Region = (aws configure get region 2>$null) }
if (-not $Region) { $Region = "eu-west-1" }

Write-Host "== Strumenti locali"
$tf = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $tf) {
    Err "terraform non trovato nel PATH"
} else {
    $line = (terraform version | Select-Object -First 1)
    if ($line -match "v(\d+)\.(\d+)\.(\d+)") {
        $v = [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
        if ($v -ge [version]"1.10.0") { Ok "$line (minimo richiesto: 1.10.0)" }
        else { Err "$line e troppo vecchio: serve 1.10.0 o successiva (backend S3 con lock nativo)" }
    } else { Warn "versione di terraform non riconosciuta: $line" }
}

if (-not $awsCmd) {
    Err "AWS CLI (aws) non trovata nel PATH"
} else {
    $awsv = (aws --version 2>&1 | Select-Object -First 1)
    if ("$awsv" -like "aws-cli/2*") { Ok "$awsv" } else { Warn "${awsv}: si consiglia AWS CLI versione 2" }
}

if (Get-Command git -ErrorAction SilentlyContinue) { Ok (git --version) } else { Warn "git non trovato (serve dal giorno 3)" }
if (Get-Command code -ErrorAction SilentlyContinue) { Ok "VS Code presente" } else { Warn "VS Code non trovato nel PATH (facoltativo, ma consigliato)" }

$key = Join-Path $HOME ".ssh\id_rsa.pub"
if (Test-Path $key) { Ok "chiave SSH pubblica trovata: $key" }
else { Warn "chiave SSH mancante: prima del Lab 3 esegui  ssh-keygen -t rsa -b 4096" }

Write-Host ""
Write-Host "== Accesso ad AWS (regione: $Region)"
if (-not $awsCmd) {
    Err "controlli AWS saltati: manca aws"
} else {
    $ident = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    if (-not $ident) {
        Err "credenziali assenti o scadute: esegui  aws configure  oppure  aws sso login"
    } else {
        Ok "account: $($ident.Account)"
        Ok "identita: $($ident.Arn)"

        if ($Region -in "eu-south-1", "eu-south-2", "me-south-1", "af-south-1", "ap-east-1", "ap-southeast-3", "il-central-1") {
            Warn "$Region e una regione opt-in: va attivata nell'account prima dell'uso. I lab usano eu-west-1."
        }

        $offered = aws ec2 describe-instance-type-offerings --region $Region --filters "Name=instance-type,Values=$InstanceType" --query "InstanceTypeOfferings[].InstanceType" --output text 2>$null
        if ($offered) { Ok "tipo di istanza $InstanceType disponibile in $Region" }
        else { Warn "tipo di istanza $InstanceType non verificabile o non disponibile in $Region (Lab 3, variabile instance_type)" }

        aws s3api list-buckets --query "length(Buckets)" --output text 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Ok "S3 raggiungibile con queste credenziali" }
        else { Warn "impossibile elencare i bucket S3: controlla i permessi (servono per i Lab 2 e 6)" }
    }
}

Write-Host ""
Write-Host "== Rete (HTTPS, porta 443)"
$hosts = "registry.terraform.io", "releases.hashicorp.com", "github.com", "sts.$Region.amazonaws.com", "s3.$Region.amazonaws.com", "ec2.$Region.amazonaws.com"
foreach ($h in $hosts) {
    if (Test-NetConnection -ComputerName $h -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue) { Ok "raggiungibile: $h" }
    else { Err "non raggiungibile: $h (proxy, VPN o firewall?)" }
}
if ($env:HTTPS_PROXY) { Warn "HTTPS_PROXY impostato: $env:HTTPS_PROXY (Terraform e aws lo useranno)" }

Write-Host ""
Write-Host "Riepilogo: $ok OK, $warn attenzione, $err errori"
if ($err -gt 0) { exit 1 } else { exit 0 }
