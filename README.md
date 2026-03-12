# 🚢 Private Docker Registry on Kubernetes (EKS + Harbor + Dex + GitHub OAuth)

A production-grade, self-hosted private Docker/OCI image registry deployed on AWS EKS — with SSO authentication via GitHub OAuth, automated TLS via Let's Encrypt, image vulnerability scanning via Trivy, and infrastructure provisioned entirely through Terraform.

---

## 📐 Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                               AWS Cloud                                         │
│                                                                                 │
│   Developer / CI-CD Pipeline                                                    │
│         │                                                                       │
│         │  docker login / docker push                                           │
│         ▼                                                                       │
│   ┌─────────────────┐                                                           │
│   │  AWS NLB        │  ← Network Load Balancer (provisioned by NGINX Ingress)   │
│   └────────┬────────┘                                                           │
│            │ :443 (TLS passthrough)                                             │
│            ▼                                                                    │
│   ┌──────────────────────────────────────────────────────────┐                  │
│   │                     EKS Cluster                          │                  │
│   │                                                          │                  │
│   │  ┌─────────────────────────────────────────────────┐     │                  │
│   │  │           NGINX Ingress Controller               │     │                  │
│   │  │  (TLS termination using cert-manager secrets)   │     │                  │
│   │  └──────────────┬────────────────┬─────────────────┘     │                  │
│   │                 │                │                        │                  │
│   │    harbor.*     │                │ dex.*                  │                  │
│   │                 ▼                ▼                        │                  │
│   │  ┌──────────────────┐  ┌─────────────────┐               │                  │
│   │  │   Harbor         │  │   Dex (OIDC)    │               │                  │
│   │  │  - Portal        │  │  - GitHub       │               │                  │
│   │  │  - Core API      │  │    Connector    │               │                  │
│   │  │  - Registry      │  │  - Token Issue  │               │                  │
│   │  │  - Trivy Scanner │  └────────┬────────┘               │                  │
│   │  │  - Job Service   │           │                        │                  │
│   │  │  - Redis Cache   │           │ (OIDC callback)        │                  │
│   │  │  - PostgreSQL DB │           ▼                        │                  │
│   │  └──────────────────┘  ┌────────────────┐                │                  │
│   │                        │  github.com    │                │                  │
│   │  ┌──────────────────┐  │  OAuth App     │                │                  │
│   │  │   cert-manager   │  └────────────────┘                │                  │
│   │  │  (Let's Encrypt) │                                    │                  │
│   │  └──────────────────┘                                    │                  │
│   │                                                          │                  │
│   │  ┌──────────────────┐                                    │                  │
│   │  │   EBS CSI Driver │  ← Provisions gp3 volumes for     │                  │
│   │  │   (gp3 volumes)  │    Harbor persistence              │                  │
│   │  └──────────────────┘                                    │                  │
│   └──────────────────────────────────────────────────────────┘                  │
│                                                                                 │
│   ┌──────────────────┐  ┌──────────────────┐                                    │
│   │   VPC            │  │   S3 Bucket      │                                    │
│   │  (public/private │  │  (Terraform      │                                    │
│   │   subnets)       │  │   remote state)  │                                    │
│   └──────────────────┘  └──────────────────┘                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

### GitHub OAuth / OIDC Login Flow

```
  Browser                Harbor              Dex                GitHub
     │                     │                  │                    │
     │── Click OIDC Login ─▶│                  │                    │
     │                     │── Redirect ──────▶│                    │
     │                     │                  │── OAuth Redirect ──▶│
     │                     │                  │                    │ (User clicks Authorize)
     │                     │                  │◀── Auth Code ──────│
     │                     │                  │── Exchange for Token│
     │                     │                  │   (validates with   │
     │                     │                  │    GitHub API)      │
     │                     │◀── OIDC Token ───│                    │
     │◀── Logged Into Harbor│                  │                    │
     │                     │                  │                    │
```

---

### Docker CLI Push Flow (with OIDC)

```
  Developer CLI                     Harbor                    Registry Storage
        │                              │                            │
        │── docker login ─────────────▶│                            │
        │   (user: OIDC username)      │                            │
        │   (pass: Harbor CLI Secret)  │                            │
        │◀── Login Succeeded ──────────│                            │
        │                              │                            │
        │── docker push image:tag ────▶│                            │
        │                              │── Trivy Scan (if enabled) ─▶
        │                              │                            │
        │                              │── Store on EBS gp3 ───────▶│
        │◀── Push Succeeded ───────────│                            │
```

---

## 🗂️ Project Structure

```
Kubernetes_Docker_registry/
├── terraform/
│   ├── backend.tf               # S3 remote state backend
│   ├── main.tf                  # Root module (VPC, EKS, IRSA, EBS CSI)
│   ├── variable.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── vpc/                 # VPC with public/private subnets
│       ├── eks/                 # EKS cluster + managed node groups
│       ├── irsa/                # IAM Roles for Service Accounts
│       ├── ebs-csi-driver/      # EBS CSI Driver for persistent storage
│       └── velero-backup/       # (Optional) Cluster backup via Velero
│
└── manifest/
    ├── namespace.yaml           # registryproject namespace
    ├── clusterissuer.yaml       # Let's Encrypt ClusterIssuer (cert-manager)
    ├── harbor-ingress.yaml      # Harbor Ingress resource
    ├── harbor-values.yaml       # Harbor Helm values (OIDC, TLS, storage)
    ├── dex-values.yaml          # Dex Helm values (GitHub connector, static clients)
    └── alb-iam-policy.json      # IAM policy for ALB controller (reference)
```

---

## 🧰 Technology Stack

| Layer | Technology |
|---|---|
| Cloud Provider | AWS |
| Compute | EKS (Elastic Kubernetes Service) |
| Infrastructure-as-Code | Terraform |
| Container Registry | Harbor |
| OIDC Identity Provider | Dex |
| Identity Source | GitHub OAuth |
| Ingress Controller | NGINX Ingress |
| Load Balancer | AWS Network Load Balancer (NLB) |
| TLS Certificates | cert-manager + Let's Encrypt |
| Persistent Storage | AWS EBS (gp3) via EBS CSI Driver |
| Image Vulnerability Scanning | Trivy (built into Harbor) |
| Package Manager | Helm |

---

## ✨ Key Features

- **Private, self-hosted OCI-compliant registry** — full control over your images, no vendor lock-in beyond AWS.
- **GitHub SSO via OIDC** — Developers log in using their GitHub accounts through Dex (no separate passwords to manage).
- **Automated TLS** — cert-manager automatically provisions and renews Let's Encrypt certificates for both `harbor.*` and `dex.*` domains.
- **Image Vulnerability Scanning** — Trivy is integrated directly into Harbor to scan images on push automatically.
- **Production-grade HA configuration** — Harbor Portal, Core, and Registry all run with multiple replicas and rolling update strategy.
- **Persistent storage with EBS gp3** — Registry, database, cache, and Trivy all use separate gp3 EBS volumes, provisioned automatically by the EBS CSI driver.
- **Infrastructure-as-Code** — All AWS infrastructure (VPC, EKS, IAM, nodes) is defined and managed via Terraform modules.

---

## 🚀 Quick Start

See [infra_setup.md](./infra_setup.md) for the full step-by-step bring-up and teardown guide.

### Prerequisites
- AWS CLI configured with appropriate permissions
- `kubectl`, `helm`, `terraform` installed locally
- A registered domain with DNS management access
- A GitHub OAuth App created at `github.com/settings/developers`

### Summary of Deployment Steps
1. `terraform apply` — Provision VPC, EKS cluster, IAM roles, EBS CSI
2. Install `cert-manager` + apply `ClusterIssuer`
3. Install `ingress-nginx` (provisions AWS NLB)
4. Install `dex` with GitHub OAuth config
5. Install `harbor` with OIDC config pointing to Dex
6. Update DNS CNAME records to point to NLB hostname
7. Configure Harbor Web UI → Authentication → OIDC

---

## 🔐 CLI Authentication (OIDC)

Since Harbor runs in OIDC mode, CLI login uses a Harbor-issued **CLI Secret** instead of your GitHub password:

1. Log into Harbor Web UI via the **"Login via OIDC"** button.
2. Click your username → **User Profile** → copy your **CLI Secret**.
3. Log in from the terminal:
   ```bash
   docker login harbor.sudheeshbalakrishna.in -u <your-username>
   # Paste CLI Secret as the password
   ```
4. Push images as normal:
   ```bash
   docker push harbor.sudheeshbalakrishna.in/<project>/<image>:<tag>
   ```

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.