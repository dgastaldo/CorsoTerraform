#!/usr/bin/env bash
# Verifica i prerequisiti tecnici per i laboratori DVO05 (solo letture, non crea nulla).
# Uso:  ./verifica-prerequisiti.sh            (regione predefinita: westeurope)
#       LOCATION=northeurope ./verifica-prerequisiti.sh
# Funziona su Linux, macOS, Git Bash e Azure Cloud Shell.

LOCATION="${LOCATION:-westeurope}"
VM_SIZE="${VM_SIZE:-Standard_B1s}"
ok=0; warn=0; err=0
ok()   { printf '[OK]          %s\n' "$1"; ok=$((ok+1)); }
warn() { printf '[ATTENZIONE]  %s\n' "$1"; warn=$((warn+1)); }
err()  { printf '[ERRORE]      %s\n' "$1"; err=$((err+1)); }

echo "== Strumenti locali"
if command -v terraform >/dev/null 2>&1; then
  line=$(terraform version | head -n 1)
  ver=$(printf '%s' "$line" | sed -E 's/^Terraform v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
  major=${ver%%.*}; rest=${ver#*.}; minor=${rest%%.*}
  if [ "$major" -gt 1 ] || { [ "$major" -eq 1 ] && [ "$minor" -ge 9 ]; }; then
    ok "$line (minimo richiesto: 1.9.0)"
  else
    err "$line e troppo vecchio: serve 1.9.0 o successiva"
  fi
else
  err "terraform non trovato nel PATH"
fi

if command -v az >/dev/null 2>&1; then
  ok "Azure CLI $(az version --query '"azure-cli"' -o tsv 2>/dev/null)"
else
  err "Azure CLI (az) non trovata nel PATH"
fi

if command -v git >/dev/null 2>&1; then ok "$(git --version)"; else warn "git non trovato (serve dal giorno 3)"; fi
if command -v code >/dev/null 2>&1; then ok "VS Code presente"; else warn "VS Code non trovato nel PATH (facoltativo, ma consigliato)"; fi
if [ -f "$HOME/.ssh/id_rsa.pub" ]; then ok "chiave SSH pubblica trovata: $HOME/.ssh/id_rsa.pub"
else warn "chiave SSH mancante: prima del Lab 3 esegui  ssh-keygen -t rsa -b 4096"; fi

echo
echo "== Accesso ad Azure"
if ! command -v az >/dev/null 2>&1; then
  err "controlli Azure saltati: manca az"
elif ! az account show >/dev/null 2>&1; then
  err "nessun login attivo: esegui  az login"
else
  ok "login attivo: $(az account show --query user.name -o tsv)"
  ok "subscription: $(az account show --query name -o tsv)"

  for ns in Microsoft.Network Microsoft.Compute Microsoft.Storage; do
    st=$(az provider show -n "$ns" --query registrationState -o tsv 2>/dev/null)
    if [ "$st" = "Registered" ]; then ok "resource provider $ns registrato"
    else warn "resource provider $ns non registrato (stato: $st). Se hai i permessi: az provider register --namespace $ns"; fi
  done

  me=$(az ad signed-in-user show --query id -o tsv 2>/dev/null)
  if [ -n "$me" ]; then
    roles=$(az role assignment list --assignee "$me" --include-inherited --include-groups --all --query "[].roleDefinitionName" -o tsv 2>/dev/null | sort -u)
    if printf '%s\n' "$roles" | grep -qxE 'Owner|Contributor'; then ok "ruoli trovati: $(printf '%s' "$roles" | tr '\n' ' ')"
    else warn "nessun ruolo Contributor/Owner visibile per il tuo utente. Controlla con chi gestisce la subscription."; fi
    if printf '%s\n' "$roles" | grep -qxE 'Owner|User Access Administrator'; then ok "puoi assegnare ruoli (serve per il Lab 6)"
    else warn "non risulti Owner o User Access Administrator: nel Lab 6 serve poter assegnare ruoli"; fi
  else
    warn "impossibile leggere l'identita dell'utente (az ad signed-in-user): ruoli non verificati"
  fi

  sku=$(az vm list-skus -l "$LOCATION" --size "$VM_SIZE" --resource-type virtualMachines \
        --query "[?name=='$VM_SIZE'] | [?length(restrictions) == \`0\`].name" -o tsv 2>/dev/null)
  if [ -n "$sku" ]; then ok "SKU $VM_SIZE disponibile in $LOCATION"
  else warn "SKU $VM_SIZE non disponibile in $LOCATION per questa subscription: scegli un'altra regione o SKU (Lab 3, variabile vm_size)"; fi

  quota=$(az vm list-usage -l "$LOCATION" --query "[?name.value=='standardBSFamily'] | [0].[currentValue,limit]" -o tsv 2>/dev/null | tr '	
' '  ')
  if [ -n "$quota" ]; then
    cur=$(printf '%s' "$quota" | awk '{print $1}'); lim=$(printf '%s' "$quota" | awk '{print $2}')
    if [ $((lim - cur)) -ge 1 ]; then ok "quota vCPU serie B in $LOCATION: $((lim - cur)) liberi su $lim"
    else warn "quota vCPU serie B esaurita in $LOCATION"; fi
  else
    warn "quota serie B non leggibile in $LOCATION"
  fi
fi

echo
echo "== Rete (HTTPS, porta 443)"
for h in registry.terraform.io releases.hashicorp.com github.com login.microsoftonline.com management.azure.com; do
  # qualsiasi risposta HTTP (anche 4xx) dimostra che il server e raggiungibile
  code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "https://$h" 2>/dev/null)
  if [ -n "$code" ] && [ "$code" != "000" ]; then ok "raggiungibile: $h"
  else err "non raggiungibile: $h (proxy, VPN o firewall?)"; fi
done
[ -n "$HTTPS_PROXY" ] && warn "HTTPS_PROXY impostato: $HTTPS_PROXY (Terraform e az lo useranno)"

echo
echo "Riepilogo: $ok OK, $warn attenzione, $err errori"
[ "$err" -gt 0 ] && exit 1
exit 0
