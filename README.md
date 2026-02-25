# ☁️ CloudOps Vault Lab

> **A production-grade cloud infrastructure built from scratch on GCP — demonstrating secure secrets management, Linux hardening, database operations, and Infrastructure as Code.**

[![Infrastructure](https://img.shields.io/badge/GCP-europe--west1-blue?logo=googlecloud)](https://cloud.google.com)
[![IaC](https://img.shields.io/badge/Terraform-v1.5.7-purple?logo=terraform)](https://terraform.io)
[![Secrets](https://img.shields.io/badge/Vault-v1.21.3-yellow?logo=vault)](https://vaultproject.io)
[![Config](https://img.shields.io/badge/Ansible-13.4-red?logo=ansible)](https://ansible.com)
[![Live](https://img.shields.io/badge/Dashboard-Live-brightgreen)](http://34.76.242.73)

**🔴 Live Dashboard → [http://34.76.242.73](http://34.76.242.73)**

---

## 📐 Architecture

```
Internet
    │
    │  HTTP :80
    ▼
┌─────────────────────────────────────────────────────────┐
│                   GCP VPC · cloudops-vpc                │
│                                                         │
│   subnet-app (10.0.1.0/24)                              │
│   ┌─────────────────┐     ┌─────────────────┐           │
│   │   app-server    │────▶│  vault-server   │           │
│   │   10.0.1.2      │     │   10.0.1.3      │           │
│   │   Flask :80     │     │   Vault :8200   │           │
│   └────────┬────────┘     └─────────────────┘           │
│            │ credentials (fetched at runtime)           │
│            │                                            │
│   subnet-db (10.0.2.0/24)                               │
│   ┌─────────────────────────────────┐                   │
│   │           db-server             │                   │
│   │           10.0.2.2              │                   │
│   │  PostgreSQL :5432  Mongo :27017 │                   │
│   └─────────────────────────────────┘                   │
│                                                         │
│   Firewall: deny-all-ingress default                    │
│   SSH: restricted · DB ports: internal only             │
└─────────────────────────────────────────────────────────┘
```

**The key security insight:** The app never holds credentials. At runtime, it authenticates to Vault with a read-only token and fetches database passwords on demand. Zero hardcoded secrets anywhere in the codebase.

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Cloud | Google Cloud Platform | Compute, networking, IAM |
| IaC | Terraform v1.5.7 | Provision all GCP resources from code |
| Config | Ansible 13.4 | VM hardening & software deployment |
| Secrets | HashiCorp Vault v1.21.3 | Runtime credential management |
| Database | PostgreSQL 15 | Relational data · least-privilege user |
| Database | MongoDB 7.0 | Document store · SCRAM-SHA-256 auth |
| App | Python Flask | Dashboard API + status endpoint |
| OS | Debian 12 | All 3 VMs · CIS benchmark hardened |
| CI/CD | GitHub Actions | Terraform validate + Ansible lint + Trivy |

---

## 📁 Repository Structure

```
cloudops-vault-lab/
├── terraform/          # GCP infrastructure as code
│   └── main.tf         # VPC, subnets, VMs, firewall rules
├── ansible/            # VM configuration
│   ├── inventory.yml   # Host definitions
│   ├── ansible.cfg     # Connection config
│   ├── harden.yml      # CIS benchmark hardening playbook
│   └── postgres.yml    # PostgreSQL deployment playbook
├── app/                # Dashboard application
│   ├── app.py          # Flask API + Vault integration
│   └── index.html      # Enterprise dashboard UI
├── vault/              # Vault policies
├── databases/          # DB setup scripts
├── monitoring/         # Prometheus/Grafana (planned)
├── docs/               # Architecture diagrams
└── .github/workflows/  # CI/CD pipeline
    └── deploy.yml
```

---

## 🚀 What Was Built (Day by Day)

### Day 1 — GCP Infrastructure with Terraform
Provisioned the entire network from a single `terraform apply`:
- Custom VPC `cloudops-vpc` with 2 isolated subnets
- 3 Debian 12 VMs: `vault-server`, `app-server`, `db-server`
- Firewall: deny-all-ingress default + explicit allow rules only where needed
- SSH access restricted to authorized IPs only

### Day 2 — Linux Hardening & Databases (Ansible)
Configured all 3 VMs via Ansible playbooks — no manual SSH:
- CIS benchmark hardening: `PermitRootLogin no`, `PasswordAuthentication no`
- Fail2ban installed and enabled on all hosts
- PostgreSQL 15 deployed on `db-server` with `cloudops_db` database and `app_user` with least-privilege access
- MongoDB 7.0 deployed with SCRAM-SHA-256 authentication enabled

### Day 3 — HashiCorp Vault & HA
- Vault installed and configured as a systemd service
- Initialized with Shamir's Secret Sharing: 5 keys, threshold of 3 (quorum-based unsealing)
- KV-v2 secrets engine enabled at `cloudops/`
- PostgreSQL and MongoDB credentials stored as Vault secrets
- Read-only `app-policy` created: app can read secrets but never write them
- Verified: write attempt with app token returns `403 permission denied`
- GCP Load Balancer with health checks configured for HA

### Day 4 — Dashboard & CI/CD
- Flask app deployed on `app-server` serving live infrastructure status
- Dashboard fetches credentials from Vault at runtime to check DB connectivity
- Systemd service ensures auto-restart on reboot
- GitHub Actions pipeline: Terraform validate + fmt check, Ansible lint, Trivy security scan

---

## 🔐 Security Architecture

**Secrets Management**
- No hardcoded credentials anywhere in the code
- App authenticates to Vault using a scoped token (`app-policy`)
- Token has `read` and `list` capabilities only — write is explicitly denied
- Vault uses Shamir's Secret Sharing: requires 3 of 5 keys to unseal

**Network Security**
- `deny-all-ingress` firewall rule at priority 65534 (catch-all default)
- DB ports (5432, 27017) only accessible from `subnet-app` (10.0.1.0/24) — never from internet
- Vault port (8200) not exposed to public internet
- SSH restricted by source IP

**Host Security (CIS Benchmarks)**
- Root SSH login disabled
- Password authentication disabled (key-only)
- Fail2ban active on all hosts
- Sensitive file permissions enforced (`/etc/ssh/sshd_config` mode 0600)

**Database Security**
- PostgreSQL: `app_user` has privileges on `cloudops_db` only
- MongoDB: authentication enabled with SCRAM-SHA-256, `app_user` limited to `readWrite` on `cloudops_db`

---

## ⚡ Quick Start

**Prerequisites**
- GCP account with billing enabled
- Terraform CLI, gcloud CLI, Ansible installed
- GitHub account

```bash
# 1. Clone
git clone https://github.com/Khalil-secure/cloudops-vault-lab.git
cd cloudops-vault-lab

# 2. Authenticate
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 3. Enable APIs
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com

# 4. Provision infrastructure
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# 5. Harden VMs
cd ../ansible
ansible-playbook -i inventory.yml harden.yml

# 6. Deploy databases
ansible-playbook -i inventory.yml postgres.yml

# 7. SSH into vault-server and initialize Vault
gcloud compute ssh vault-server --zone=europe-west1-b
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init
vault operator unseal  # run 3x with different keys
vault login ROOT_TOKEN
vault secrets enable -path=cloudops kv-v2
vault kv put cloudops/postgres username=app_user password=YOUR_PASS host=10.0.2.2 port=5432 database=cloudops_db
vault kv put cloudops/mongodb username=app_user password=YOUR_PASS host=10.0.2.2 port=27017

# 8. Deploy dashboard on app-server
gcloud compute scp app/app.py app-server:~/app/app.py --zone=europe-west1-b
gcloud compute scp app/index.html app-server:~/app/index.html --zone=europe-west1-b
gcloud compute ssh app-server --zone=europe-west1-b
sudo systemctl restart cloudops
```

Dashboard available at `http://YOUR_APP_SERVER_EXTERNAL_IP`

---

## 🗺️ How This Maps to Tech-Ops Integrator Requirements

| Requirement | Evidence in this project |
|---|---|
| Cloud infrastructure (GCP) | VPC, subnets, Compute Engine, IAM, firewall rules — all via Terraform |
| Linux expert | CIS hardening, SSH config, Fail2ban, systemd services on Debian 12 |
| High Availability | GCP Load Balancer + health checks + failover configuration |
| YAML / HTML/CSS | Ansible playbooks (YAML) + enterprise dashboard (HTML/CSS) |
| Virtualisation | GCP Compute Engine (3 VMs) + prior VMware→Hyper-V migration at ETEX |
| PostgreSQL & MongoDB | Both deployed, authenticated, and monitored in production |
| Agile / Project Mgmt | GitHub Projects Kanban board — see Projects tab |
| Vault / CyberArk | Full Vault deployment: init, unseal, KV-v2, policies, app tokens |

---

## 👤 Author

**M. Khalil Ghiati**  
Ingénieur diplômé en Électronique & Télécommunications  
Specialized in infrastructure and critical systems

[github.com/Khalil-secure](https://github.com/Khalil-secure) · 07 74 73 89 29
