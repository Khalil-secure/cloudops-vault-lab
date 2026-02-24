# ☁️ CloudOps Vault Lab

![WIP](./wip-logo.svg)


> Production-grade cloud infrastructure on GCP — fully automated, hardened, and secrets-managed.

![CI/CD Pipeline](https://github.com/Khalil-secure/cloudops-vault-lab/actions/workflows/deploy.yml/badge.svg)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![GCP](https://img.shields.io/badge/Cloud-GCP-4285F4?logo=google-cloud&logoColor=white)
![Vault](https://img.shields.io/badge/Secrets-Vault-000000?logo=vault)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📐 Architecture

```
Internet
    │
    ▼
GCP Load Balancer  (:80)
    │
    ▼
┌─────────────── subnet-app (10.0.1.0/24) ────────────────┐
│  app-server (e2-micro)       vault-server (e2-micro)     │
│  Python app · :80            HashiCorp Vault · :8200     │
└──────────────────────────────────────────────────────────┘
    │ DB queries (internal)
    ▼
┌─────────────── subnet-db (10.0.2.0/24) ─────────────────┐
│  db-server (e2-micro)                                    │
│  PostgreSQL · :5432          MongoDB · :27017            │
└──────────────────────────────────────────────────────────┘

Firewall: deny-by-default · SSH restricted to admin IP only
Secrets:  all DB credentials stored in Vault — zero hardcoded secrets
State:    remote GCS backend with versioning enabled
```

---

## 🛠️ Stack

| Layer | Tool |
|---|---|
| Cloud Provider | Google Cloud Platform (us-central1) |
| Infrastructure as Code | Terraform + GCS remote state |
| Configuration Management | Ansible (CIS-hardened playbooks) |
| Secrets Management | HashiCorp Vault (KV v2) |
| Databases | PostgreSQL 15 + MongoDB 7 |
| High Availability | GCP Load Balancer + Health Checks |
| CI/CD | GitHub Actions (Terraform validate · Ansible lint · Trivy scan) |
| Security | UFW · Fail2ban · SSH hardening · ANSSI/CIS benchmarks |

---

## 🚀 Quick Start

**Prerequisites:** `gcloud` CLI, `terraform` ≥ 1.7, `ansible` ≥ 2.15, GCP project with billing enabled.

```bash
# 1. Clone
git clone https://github.com/Khalil-secure/cloudops-vault-lab.git
cd cloudops-vault-lab

# 2. Create GCS bucket for Terraform state
gsutil mb gs://cloudops-tfstate-khalil
gsutil versioning set on gs://cloudops-tfstate-khalil

# 3. Deploy infrastructure
cd terraform/
terraform init && terraform apply

# 4. Harden VMs (dry-run first)
ansible-playbook -i ansible/inventory.yml ansible/harden.yml --check
ansible-playbook -i ansible/inventory.yml ansible/harden.yml

# 5. Deploy databases
ansible-playbook -i ansible/inventory.yml ansible/postgres.yml
ansible-playbook -i ansible/inventory.yml ansible/mongodb.yml

# 6. Initialize Vault (save keys immediately!)
export VAULT_ADDR="http://VAULT_IP:8200"
vault operator init | tee ~/vault-keys-BACKUP.txt
vault operator unseal  # × 3
```

> ⚠️ **Before running Step 4:** test SSH manually into every VM first.  
> ⚠️ **After Step 6:** upload unseal keys to GCP Secret Manager immediately.

---

## 🔐 Security Features

- **Deny-by-default firewall** — all inbound traffic blocked except explicit allow rules
- **Linux hardening** — SSH key-only auth, PermitRootLogin disabled, CIS/ANSSI benchmarks via Ansible
- **Zero hardcoded secrets** — all DB credentials stored in Vault, read at runtime via API
- **Least-privilege IAM** — dedicated GCP Service Account for CI/CD with read-only permissions
- **Fail2ban** — automatic IP banning on repeated failed SSH attempts
- **Trivy** — container and filesystem vulnerability scanning in every CI run

---

## 📁 Structure

```
cloudops-vault-lab/
├── terraform/          # GCP infra (VPC, VMs, firewall, LB)
├── ansible/            # Hardening + DB deployment playbooks
├── vault/              # Vault config, policies, unseal scripts
├── app/                # Status dashboard (HTML/CSS)
├── docs/               # Architecture diagrams, screenshots
└── .github/workflows/  # CI/CD: validate + lint + security scan
```

---

## 🧪 Verify Everything Works

```bash
# Vault status
vault status && vault kv list cloudops/

# PostgreSQL
psql -U app_user -d cloudops_db -h localhost -W

# MongoDB
mongosh -u admin --authenticationDatabase admin --eval "db.runCommand({ping:1})"

# Load Balancer health
curl http://LB_EXTERNAL_IP/health   # → OK
```

---

## 👤 Author

**M. Khalil Ghiati** — Infrastructure & Security Engineer  
[github.com/Khalil-secure](https://github.com/Khalil-secure) · [portfolio-khalil-secure.vercel.app](https://portfolio-khalil-secure.vercel.app)
