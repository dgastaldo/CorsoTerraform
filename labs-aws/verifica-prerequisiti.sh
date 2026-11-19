#!/usr/bin/env bash
# Verifica i prerequisiti tecnici per i laboratori DVO05 su AWS (solo letture, non crea nulla).
# Uso:  ./verifica-prerequisiti.sh            (regione: AWS_REGION, altrimenti quella di aws configure, altrimenti eu-west-1)
#       AWS_REGION=eu-central-1 ./verifica-prerequisiti.sh
# Funziona su Linux, macOS, Git Bash e AWS CloudShell.

INSTANCE_TYPE="${INSTANCE_TYPE:-t3.micro}"
ok=0; warn=0; err=0
ok()   { printf '[OK]          %s\n' "$1"; ok=$((ok+1)); }
warn() { printf '[ATTENZIONE]  %s\n' "$1"; warn=$((warn+1)); }
err()  { printf '[ERRORE]      %s\n' "$1"; err=$((err+1)); }

REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"
if [ -z "$REGION" ] && command -v aws >/dev/null 2>&1; then REGION=$(aws configure get region 2>/dev/null); fi
REGION="${REGION:-eu-west-1}"

echo "== Strumenti locali"
if command -v terraform >/dev/null 2>&1; then
  line=$(terraform version | head -n 1)
  ver=$(printf '%s' "$line" | sed -E 's/^Terraform v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
  major=${ver%%.*}; rest=${ver#*.}; minor=${rest%%.*}
  if [ "$major" -gt 1 ] || { [ "$major" -eq 1 ] && [ "$minor" -ge 10 ]; }; then
    ok "$line (minimo richiesto: 1.10.0)"
  else
    err "$line e troppo vecchio: serve 1.10.0 o successiva (backend S3 con lock nativo)"
  fi
else
  err "terraform non trovato nel PATH"
fi

if command -v aws >/dev/null 2>&1; then
  awsv=$(aws --version 2>&1 | head -n 1)
  case "$awsv" in
    aws-cli/2*) ok "$awsv" ;;
    *) warn "$awsv: si consiglia AWS CLI versione 2" ;;
  esac
else
  err "AWS CLI (aws) non trovata nel PATH"
fi

if command -v git >/dev/null 2>&1; then ok "$(git --version)"; else warn "git non trovato (serve dal giorno 3)"; fi
if command -v code >/dev/null 2>&1; then ok "VS Code presente"; else warn "VS Code non trovato nel PATH (facoltativo, ma consigliato)"; fi
if [ -f "$HOME/.ssh/id_rsa.pub" ]; then ok "chiave SSH pubblica trovata: $HOME/.ssh/id_rsa.pub"
else warn "chiave SSH mancante: prima del Lab 3 esegui  ssh-keygen -t rsa -b 4096"; fi

echo
echo "== Accesso ad AWS (regione: $REGION)"
if ! command -v aws >/dev/null 2>&1; then
  err "controlli AWS saltati: manca aws"
elif ! ident=$(aws sts get-caller-identity --query '[Account,Arn]' --output text 2>/dev/null); then
  err "credenziali assenti o scadute: esegui  aws configure  oppure  aws sso login"
else
  ok "account: $(printf '%s' "$ident" | awk '{print $1}')"
  ok "identita: $(printf '%s' "$ident" | awk '{print $2}')"

  case "$REGION" in
    eu-south-1|eu-south-2|me-south-1|af-south-1|ap-east-1|ap-southeast-3|il-central-1)
      warn "$REGION e una regione opt-in: va attivata nell'account prima dell'uso. I lab usano eu-west-1." ;;
  esac

  offered=$(aws ec2 describe-instance-type-offerings --region "$REGION" \
            --filters "Name=instance-type,Values=$INSTANCE_TYPE" \
            --query 'InstanceTypeOfferings[].InstanceType' --output text 2>/dev/null)
  if [ -n "$offered" ]; then ok "tipo di istanza $INSTANCE_TYPE disponibile in $REGION"
  else warn "tipo di istanza $INSTANCE_TYPE non verificabile o non disponibile in $REGION (Lab 3, variabile instance_type)"; fi

  if aws s3api list-buckets --query 'length(Buckets)' --output text >/dev/null 2>&1; then ok "S3 raggiungibile con queste credenziali"
  else warn "impossibile elencare i bucket S3: controlla i permessi (servono per i Lab 2 e 6)"; fi
fi

echo
echo "== Rete (HTTPS, porta 443)"
for h in registry.terraform.io releases.hashicorp.com github.com "sts.$REGION.amazonaws.com" "s3.$REGION.amazonaws.com" "ec2.$REGION.amazonaws.com"; do
  # qualsiasi risposta HTTP (anche 4xx) dimostra che il server e raggiungibile
  code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "https://$h" 2>/dev/null)
  if [ -n "$code" ] && [ "$code" != "000" ]; then ok "raggiungibile: $h"
  else err "non raggiungibile: $h (proxy, VPN o firewall?)"; fi
done
[ -n "$HTTPS_PROXY" ] && warn "HTTPS_PROXY impostato: $HTTPS_PROXY (Terraform e aws lo useranno)"

echo
echo "Riepilogo: $ok OK, $warn attenzione, $err errori"
[ "$err" -gt 0 ] && exit 1
exit 0
