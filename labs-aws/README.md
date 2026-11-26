# DVO05 – Laboratori Terraform su AWS

Versione AWS dei laboratori Azure (`../labs`). Stessa struttura, stessi concetti, stessa numerazione.

## Versioni (verificate sul registry il 17/11/2026)

| Componente | Versione | Vincolo nel codice |
|---|---|---|
| Terraform CLI | 1.17.2 (provato con 1.17.1) | `>= 1.10` (serve per `use_lockfile` nel Lab 6) |
| `hashicorp/aws` | 6.73.0 | `~> 6.73` (modulo Lab 5: `>= 6.0, < 7.0`) |
| `hashicorp/random` | 3.9.1 | `~> 3.9` |
| `actions/checkout` | v7 | |
| `actions/upload-artifact` | v7 | |
| `actions/download-artifact` | v8 | |
| `hashicorp/setup-terraform` | v4 | |
| `aws-actions/configure-aws-credentials` | v6 | |

Ogni lab ha il suo `.terraform.lock.hcl` con le versioni sopra: `terraform init` installa esattamente quelle.

## Prerequisiti per gli studenti

- Terraform 1.10 o superiore e **aws CLI v2**.
- Credenziali configurate: `aws configure` oppure `aws sso login`. Verifica con `aws sts get-caller-identity`.
- Regione di default dei lab: `eu-west-1` (Irlanda). Si cambia con `-var region=...` o `TF_VAR_region`. Evita `eu-south-1` (Milano): richiede l'attivazione manuale della regione.
- Permessi: servono S3, EC2/VPC, SNS, CloudWatch Logs (Lab 1-5). Per il Lab 7 anche IAM (OIDC e ruolo).
- Chiave SSH pubblica in `~/.ssh/id_rsa.pub` (Lab 3).
- **Non esiste una registrazione dei provider come su Azure**: nessun passaggio equivalente a `az provider register`.
- Controllo automatico (solo letture): `./verifica-prerequisiti.ps1` su Windows, `./verifica-prerequisiti.sh` altrove. Controlla Terraform, aws CLI, credenziali, regione, tipo di istanza, chiave SSH e rete.

## Corrispondenza Azure → AWS

| Azure | AWS |
|---|---|
| Resource group (Lab 1) | Topic SNS `aws_sns_topic` |
| Storage account (Lab 2) | Bucket S3 + risorse collegate (public access block, versioning, cifratura) |
| `access_key` sensitive | `app_secret`, generato da `random_password` |
| `replication_type` | `versioning_status` |
| Rete virtuale, NSG, VM (Lab 3) | VPC, security group, istanza EC2 Ubuntu 24.04 |
| Data source `azurerm_client_config` | `aws_caller_identity`, `aws_availability_zones`, `aws_ami` |
| Import resource group (Lab 4) | Import log group `aws_cloudwatch_log_group` |
| Backend `azurerm` con lease | Backend `s3` con `use_lockfile = true` (senza DynamoDB) |
| Ruolo Storage Blob Data Contributor | Permessi S3 sull'utente o sul ruolo |
| Federazione OIDC con app registration | Identity provider OIDC + ruolo IAM |

## Lab 1 – Topic SNS

```bash
cd labs-aws/lab1
export TF_VAR_student=mrossi
terraform init && terraform plan      # Plan: 1 to add
terraform apply
terraform state list
```

- Modifica in place: aggiungi un tag in `tags`.
- Sostituzione: cambia `name` del topic. Il plan mostra `-/+` e `forces replacement`. Non applicare.
- Verifica: `aws sns list-topics --region eu-west-1`.

## Lab 2 – Bucket S3, variabili e validation

```bash
cd labs-aws/lab2
terraform init
terraform plan -var-file=dev.tfvars      # 6 risorse
terraform plan -var-file=dev.tfvars -var student=NOME_NON_VALIDO   # errore di validation
terraform apply -var-file=dev.tfvars
terraform output -raw app_secret         # leggibile; cercalo anche in terraform.tfstate
```

- Il nome del bucket è `tfcourse-<sigla>-<env>-<5 caratteri casuali>`.
- `terraform plan -var-file=test.tfvars` sullo stesso state: cambia l'ambiente nel nome, quindi sostituzione (`-/+`) del bucket.
- Modifica la sigla in `dev.tfvars` con la tua (il file contiene `mrossi`).
- Questo progetto si riusa nei Lab 6 e 7.

## Lab 3 – VPC, security group dinamico e EC2 con cloud-init

```bash
cd labs-aws/lab3
terraform init
terraform plan -var student=mrossi       # 9 risorse
terraform apply -var student=mrossi
terraform output web_url                 # attendi 2-3 minuti per cloud-init
terraform plan -var student=mrossi -var 'allowed_ports=[80,443]'   # cambia solo il security group
```

- Su Windows passa il percorso completo se serve: `-var ssh_public_key_path=C:/Users/<utente>/.ssh/id_rsa.pub`.
- Se `t3.micro` non è disponibile: `-var instance_type=<altro>` (vedi la descrizione della variabile).
- La porta 22 non è aperta: per entrare usa AWS Systems Manager Session Manager oppure apri la 22 con `allowed_ports=[22,80]` solo per prova.
- Il nome del security group non può iniziare con `sg-`.

## Lab 4 – Import e caccia agli errori

Parte A (`lab4/import`): crea il log group a mano.

```bash
aws logs create-log-group --log-group-name /tfcourse/legacy-mrossi --region eu-west-1
aws logs tag-log-group --log-group-name /tfcourse/legacy-mrossi --tags origine=portale --region eu-west-1
cd labs-aws/lab4/import
terraform init
terraform plan -var student=mrossi -generate-config-out=generated.tf
```

Poi segui gli stessi passi del Lab 4 Azure, con `aws_cloudwatch_log_group.legacy` → `core` nel blocco `moved`. Pulizia finale: `terraform destroy` oppure `aws logs delete-log-group --log-group-name /tfcourse/legacy-mrossi`.

Parte B (`lab4/broken`): `terraform init` e `terraform validate` mostrano gli errori a ondate.

1. Prima ondata (3 errori insieme): `count = "due"` (tipo non valido), riferimento a `aws_s3_bucket.mian` (risorsa non dichiarata), attributo `bucket_regional_domain_nam` (inesistente).
2. Seconda ondata: `status = "Enabeld"` (il provider elenca i valori ammessi).
3. Poi `validate` è verde, ma `terraform plan` fallisce con `invalid AWS Region` perché il blocco `provider "aws"` non ha la regione. Un altro problema dipende dal contesto: una sigla con lettere maiuscole non è un nome di bucket valido (non verificato con un plan reale).

## Lab 5 – Modulo di rete

```bash
cd labs-aws/lab5
terraform init
terraform plan -var student=mrossi     # 7 risorse: 2 VPC e 5 subnet
```

Su AWS non c'è il resource group: le risorse sono 7 e non 8. Gli indirizzi sono `module.network["dev"]...`.

## Lab 6 – Backend S3 con lock nativo

```bash
cd labs-aws/lab6
STUDENT=mrossi ./bootstrap-backend.sh        # PowerShell: $env:STUDENT="mrossi"; ./bootstrap-backend.ps1
# copia backend.tf e backend.hcl nella copia del progetto del Lab 2, poi:
terraform init -backend-config=backend.hcl -migrate-state
```

- Il bucket si chiama `tfstate-<sigla>-<id account>`, con versioning, cifratura e accesso pubblico bloccato.
- Il lock è un oggetto `<key>.tflock` nello stesso bucket (`use_lockfile = true`, Terraform 1.10 o superiore). Durante un apply in pausa compare nel bucket: `aws s3 ls s3://<bucket>/`.
- Workspace: gli state si trovano sotto `env:/<workspace>/<key>`.
- Pulizia: `terraform destroy` in ogni workspace, poi `aws s3 rb s3://<bucket> --force` (il bucket è versionato: se resta pieno di versioni, svuotalo dalla console).

## Lab 7 – Test e pipeline con OIDC

Parte A: copia `lab7/tests/` nel progetto del Lab 2 e lancia `terraform test` (3 test, nessuna credenziale). Con `block_public_acls = false` in `main.tf` il primo test fallisce.

Parte B: configura la federazione verso AWS.

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com
# modifica oidc/trust-policy.json: <ACCOUNT_ID>, <ORG>, <REPO>
aws iam create-role --role-name gha-tfcourse-mrossi \
  --assume-role-policy-document file://oidc/trust-policy.json
aws iam attach-role-policy --role-name gha-tfcourse-mrossi \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess   # solo per il corso: in produzione usa permessi minimi
```

Nel repository, *Settings → Secrets and variables → Actions → Variables*: `AWS_ROLE_ARN`, `AWS_REGION`, `TF_STUDENT`. Crea l'ambiente `production` con un revisore. Se l'account ha già il provider OIDC di GitHub, salta `create-open-id-connect-provider`. Il ruolo deve poter leggere e scrivere il bucket dello state del Lab 6.

Pulizia: `aws iam detach-role-policy ...`, `aws iam delete-role --role-name gha-tfcourse-mrossi`.

## Cosa è stato verificato e cosa no

Verificato, senza credenziali AWS:

- `terraform fmt -check -recursive` pulito.
- `terraform init` e `terraform validate` verdi in lab1, lab2, lab3, lab4/import, lab5; lab6 con `init -backend=false`.
- Lab 7: i 3 test passano; con `block_public_acls = false` il primo fallisce.
- Lab 3 e Lab 5: plan con provider simulato (`mock_provider`): 9 e 7 risorse, assegnazione delle zone, porte dinamiche. Questo ha trovato il nome `sg-web-...` non ammesso, già corretto.
- Lab 4 `broken`: sequenza degli errori controllata (ondate 1 e 2, poi `invalid AWS Region` al plan).
- Gli script `verifica-prerequisiti` (sh e ps1): sintassi controllata ed esecuzione completa senza aws CLI (i controlli su credenziali, regione e tipo di istanza non sono stati provati).
- Le versioni dei provider e delle Actions sono quelle più recenti sul registry e su GitHub; i tag principali (`@v7` ecc.) esistono.

**Non verificato** (nessuna credenziale AWS, aws CLI assente su questo PC):

- `plan`, `apply` e `destroy` reali, in particolare il data source `aws_ami` e la pagina nginx del Lab 3.
- Import con `-generate-config-out` del log group (Lab 4).
- Script `bootstrap-backend` e lock su S3 (Lab 6).
- Federazione OIDC, ruolo e pipeline (Lab 7).

Provali tutti su un account di prova prima del corso.
