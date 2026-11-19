# Verifica i prerequisiti tecnici per i laboratori DVO05 (solo letture, non crea nulla).
# Uso:  ./verifica-prerequisiti.ps1            (regione predefinita: westeurope)
#       ./verifica-prerequisiti.ps1 -Location northeurope
param(
    [string]$Location = "westeurope",
    [string]$VmSize = "Standard_B1s"
)

$ok = 0; $warn = 0; $err = 0
function Ok($m)   { Write-Host "[OK]          $m" -ForegroundColor Green;  $script:ok++ }
function Warn($m) { Write-Host "[ATTENZIONE]  $m" -ForegroundColor Yellow; $script:warn++ }
function Err($m)  { Write-Host "[ERRORE]      $m" -ForegroundColor Red;    $script:err++ }

Write-Host "== Strumenti locali"
# Terraform
$tf = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $tf) {
    Err "terraform non trovato nel PATH"
} else {
    $line = (terraform version | Select-Object -First 1)
    if ($line -match "v(\d+)\.(\d+)\.(\d+)") {
        $v = [version]"$($Matches[1]).$($Matches[2]).$($Matches[3])"
        if ($v -ge [version]"1.9.0") { Ok "$line (minimo richiesto: 1.9.0)" }
        else { Err "$line e troppo vecchio: serve 1.9.0 o successiva" }
    } else { Warn "versione di terraform non riconosciuta: $line" }
}

# Azure CLI
$az = Get-Command az -ErrorAction SilentlyContinue
if (-not $az) {
    Err "Azure CLI (az) non trovata nel PATH"
} else {
    $azv = (az version -o json 2>$null | ConvertFrom-Json).'azure-cli'
    Ok "Azure CLI $azv"
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) { Ok (git --version) } else { Warn "git non trovato (serve dal giorno 3)" }

# VS Code (facoltativo)
if (Get-Command code -ErrorAction SilentlyContinue) { Ok "VS Code presente" } else { Warn "VS Code non trovato nel PATH (facoltativo, ma consigliato)" }

# Chiave SSH (Lab 3)
$key = Join-Path $HOME ".ssh/id_rsa.pub"
if (Test-Path $key) { Ok "chiave SSH pubblica trovata: $key" }
else { Warn "chiave SSH mancante: prima del Lab 3 esegui  ssh-keygen -t rsa -b 4096" }

Write-Host ""
Write-Host "== Accesso ad Azure"
if (-not $az) {
    Err "controlli Azure saltati: manca az"
} else {
    $acc = az account show -o json 2>$null | ConvertFrom-Json
    if (-not $acc) {
        Err "nessun login attivo: esegui  az login"
    } else {
        Ok "login attivo: $($acc.user.name)"
        Ok "subscription: $($acc.name)"

        # Resource provider
        foreach ($ns in "Microsoft.Network", "Microsoft.Compute", "Microsoft.Storage") {
            $st = az provider show -n $ns --query registrationState -o tsv 2>$null
            if ($st -eq "Registered") { Ok "resource provider $ns registrato" }
            else { Warn "resource provider $ns non registrato (stato: $st). Se hai i permessi: az provider register --namespace $ns" }
        }

        # Ruoli
        $me = az ad signed-in-user show --query id -o tsv 2>$null
        if ($me) {
            $roles = az role assignment list --assignee $me --include-inherited --include-groups --all --query "[].roleDefinitionName" -o tsv 2>$null
            $set = @($roles | Sort-Object -Unique)
            if ($set -contains "Owner" -or $set -contains "Contributor") {
                Ok "ruoli trovati: $($set -join ', ')"
            } else {
                Warn "nessun ruolo Contributor/Owner visibile per il tuo utente (ruoli: $($set -join ', ')). Controlla con chi gestisce la subscription."
            }
            if ($set -contains "Owner" -or $set -contains "User Access Administrator") {
                Ok "puoi assegnare ruoli (serve per il Lab 6)"
            } else {
                Warn "non risulti Owner o User Access Administrator: nel Lab 6 serve poter assegnare ruoli"
            }
        } else {
            Warn "impossibile leggere l'identita dell'utente (az ad signed-in-user): ruoli non verificati"
        }

        # SKU e quota VM (Lab 3)
        $sku = az vm list-skus -l $Location --size $VmSize --resource-type virtualMachines -o json 2>$null | ConvertFrom-Json
        $free = @($sku | Where-Object { $_.name -eq $VmSize -and @($_.restrictions).Count -eq 0 })
        if ($free.Count -gt 0) { Ok "SKU $VmSize disponibile in $Location" }
        else { Warn "SKU $VmSize non disponibile in $Location per questa subscription: scegli un'altra regione o SKU (Lab 3, variabile vm_size)" }

        $usage = az vm list-usage -l $Location -o json 2>$null | ConvertFrom-Json
        $fam = $usage | Where-Object { $_.name.value -eq "standardBSFamily" }
        if ($fam) {
            $left = [int]$fam.limit - [int]$fam.currentValue
            if ($left -ge 1) { Ok "quota vCPU serie B in ${Location}: $left liberi su $($fam.limit)" }
            else { Warn "quota vCPU serie B esaurita in $Location" }
        } else { Warn "quota serie B non leggibile in $Location" }
    }
}

Write-Host ""
Write-Host "== Rete (HTTPS, porta 443)"
$hosts = "registry.terraform.io", "releases.hashicorp.com", "github.com", "login.microsoftonline.com", "management.azure.com"
foreach ($h in $hosts) {
    if (Test-NetConnection -ComputerName $h -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue) { Ok "raggiungibile: $h" }
    else { Err "non raggiungibile: $h (proxy, VPN o firewall?)" }
}
if ($env:HTTPS_PROXY) { Warn "HTTPS_PROXY impostato: $env:HTTPS_PROXY (Terraform e az lo useranno)" }

Write-Host ""
Write-Host "Riepilogo: $ok OK, $warn attenzione, $err errori"
if ($err -gt 0) { exit 1 } else { exit 0 }
