# Add Grafana Monitoring to the Docker Registry Stack

## 🎓 Grafana 101 — What Is It and Why Do You Need It?

> [!NOTE]
> Before touching a single config file, let's make sure you understand **what we're building and why**.

### The Monitoring Problem
Right now your stack (Harbor, Dex, NGINX) is running happily, but you are **blind**:
- Is Harbor using a lot of CPU? You don't know.
- How many Docker `push`/`pull` requests happened today? You don't know.
- Did NGINX reject some requests? You don't know.
- Is one of your pods restarting over and over? You'll only find out when things break.

**Monitoring solves this.** You get live graphs, historic trends, and alerts — all in a web dashboard.

---

### The Two-Tool Stack: Prometheus + Grafana

You actually need **two tools working together**:

```
┌─────────────────────┐        ┌──────────────────────┐        ┌──────────────────┐
│  Your Apps          │        │  Prometheus           │        │  Grafana         │
│  (Harbor, NGINX,    │──────>│  (Time-series DB)     │──────>│  (Dashboard UI)  │
│   Kubernetes nodes) │        │  Scrapes & stores     │        │  Visualises &    │
│                     │        │  metrics every 15s    │        │  alerts          │
└─────────────────────┘        └──────────────────────┘        └──────────────────┘
```

| Tool | Role | Analogy |
|------|------|---------|
| **Prometheus** | Collects and stores raw numbers (metrics) from your apps/nodes | A security guard who checks every room every 15 seconds and writes down what he sees |
| **Grafana** | Reads from Prometheus and draws beautiful dashboards | The big screen in a control room that shows what the guard wrote down |

**Prometheus** goes to each app, asks "hey, what are your current stats?" (this is called **scraping**), and saves that data with a timestamp. It can do this because most modern Kubernetes-native apps expose a `/metrics` HTTP endpoint with data like:

```
# How many HTTP requests nginx handled
nginx_http_requests_total{method="GET", status="200"} 4523
nginx_http_requests_total{method="POST", status="500"} 12
```

**Grafana** then reads this data from Prometheus using a query language called **PromQL** and draws charts. It has thousands of pre-built community dashboards you can import with a single click.

---

### What Will We Monitor?

| What | Exporter / Source | What you'll see in Grafana |
|------|-------------------|---------------------------|
| Kubernetes Nodes (CPU, RAM, Disk) | `node-exporter` (bundled) | Node resource usage graphs |
| Kubernetes Pods / Deployments | Kubernetes API (scraped automatically) | Pod restarts, memory limits, etc. |
| NGINX Ingress Controller | NGINX metrics endpoint | HTTP request rates, error rates, latency |
| Harbor Registry | Harbor's built-in `/metrics` endpoint | Push/pull counts, API latency |

---

## The Monitoring Bundle: `kube-prometheus-stack`

We install one Helm chart called **`kube-prometheus-stack`** (by Prometheus Community). It bundles five things in one go:

| Component | What it does |
|-----------|-------------|
| **Prometheus** | Scrapes & stores metrics from everything in the cluster |
| **Grafana** | Web dashboard UI — your main interface |
| **Node Exporter** | OS-level metrics (CPU, RAM, disk) from every EC2 node |
| **kube-state-metrics** | Kubernetes object metrics (pod counts, restarts, replica status) |
| **AlertManager** | Receives alerts from Prometheus and routes them (email/Slack/etc.) |

This is the industry-standard "batteries included" monitoring package for Kubernetes.

---

## Config File: `manifest/prometheus-stack-values.yaml`

This single Helm values file configures the entire bundle. Below is every section explained:

```yaml
# ─── GRAFANA CONFIGURATION ───────────────────────────────────────────────────

grafana:
  # Grafana needs a password for its built-in "admin" user.
  # You will use it to log into https://grafana.sudheeshbalakrishna.in
  adminPassword: "GrafanaAdmin123!"

  # grafana.ini: Grafana's internal INI config file, exposed as Helm values.
  grafana.ini:
    server:
      # domain: The public hostname Grafana is served from.
      # Used for building correct redirect URLs (e.g. for OAuth).
      domain: grafana.sudheeshbalakrishna.in

      # root_url: The full URL including the scheme (https://).
      # Without this, Grafana generates broken links in emails & OAuth callbacks.
      root_url: https://grafana.sudheeshbalakrishna.in

  # ingress: Exposes Grafana to the internet via your existing
  # NGINX Ingress Controller + cert-manager (same setup as Harbor & Dex).
  ingress:
    enabled: true            # Create the Ingress resource
    ingressClassName: nginx  # Use your existing NGINX Ingress Controller
    annotations:
      # cert-manager reads this and auto-provisions a Let's Encrypt certificate.
      # Identical annotation to what Harbor and Dex already use.
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      # Force HTTPS redirects
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    hosts:
      - grafana.sudheeshbalakrishna.in   # Public DNS name for Grafana
    tls:
      - secretName: grafana-tls          # cert-manager creates this Secret
        hosts:
          - grafana.sudheeshbalakrishna.in

  # persistence: Grafana stores dashboards, users, and settings in an
  # embedded SQLite DB inside the pod. Without persistence, everything
  # resets every time the pod restarts!
  persistence:
    enabled: true
    storageClassName: gp3   # AWS EBS gp3 SSD — same as Harbor uses
    size: 5Gi               # 5 GB is plenty for Grafana's SQLite DB
    accessModes:
      - ReadWriteOnce       # Only one pod mounts this volume at a time

  # sidecar: Helper containers that run alongside Grafana inside the same pod.
  # They watch for Kubernetes ConfigMaps labelled "grafana_dashboard: 1" and
  # hot-reload dashboards into Grafana — no restart needed.
  # The kube-prometheus-stack chart ships pre-built dashboards this way.
  sidecar:
    dashboards:
      enabled: true         # Auto-load bundled community dashboards
      searchNamespace: ALL  # Look in ALL namespaces, not just "monitoring"
    datasources:
      enabled: true         # Auto-configure the Prometheus data source


# ─── PROMETHEUS CONFIGURATION ────────────────────────────────────────────────

prometheus:
  prometheusSpec:
    # retention: How long to keep metric data before deleting it.
    # 30 days = decent history without excessive disk cost.
    retention: 30d

    # storageSpec: Give Prometheus its own EBS volume.
    # Without this, all metrics history is lost on pod restart.
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3          # AWS EBS gp3 SSD
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 20Gi             # 20 GB for raw time-series data

    # ServiceMonitor / PodMonitor selectors:
    # Prometheus discovers what to scrape via "ServiceMonitor" CRDs.
    # By default it only watches its own namespace. Setting these to {}
    # (empty = match everything) makes it watch ALL namespaces.
    # This is how it finds Harbor in "registryproject", NGINX in "ingress-nginx", etc.
    serviceMonitorNamespaceSelector: {}   # {} = no filter = ALL namespaces
    serviceMonitorSelector: {}            # {} = no filter = ALL ServiceMonitors
    podMonitorNamespaceSelector: {}
    podMonitorSelector: {}
    ruleNamespaceSelector: {}
    ruleSelector: {}


# ─── NODE EXPORTER ───────────────────────────────────────────────────────────

# Runs as a DaemonSet — one pod per EC2 node, always.
# Exposes CPU, RAM, disk I/O, and network stats for the node (not pods).
# Powers the "Node Exporter Full" Grafana dashboard.
nodeExporter:
  enabled: true


# ─── KUBE STATE METRICS ──────────────────────────────────────────────────────

# Talks to the Kubernetes API and converts object info into metrics:
#   kube_pod_container_status_restarts_total{pod="harbor-core-xxx"} 3
#   kube_deployment_status_replicas_available{deployment="harbor-registry"} 2
# Powers the "Kubernetes / Pods" and "Kubernetes / Deployments" dashboards.
kubeStateMetrics:
  enabled: true


# ─── ALERT MANAGER ───────────────────────────────────────────────────────────

# Receives alerts from Prometheus (e.g. "CPU > 90% for 5 min") and
# routes them to email, Slack, PagerDuty, etc.
# Installed but routing is left unconfigured — add it later as needed.
alertmanager:
  enabled: true
  alertmanagerSpec:
    alertmanagerConfigSelector: {}   # Silence "no receivers" warning
```

---

## How to Deploy

```bash
# 1. Add the Prometheus Community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Install the monitoring bundle
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --version 58.5.3 \
  -f manifest/prometheus-stack-values.yaml

# 3. Verify all pods are Running (takes ~2-3 minutes)
kubectl get pods -n monitoring
```

---

## DNS Record Required

Add a **CNAME** for `grafana.sudheeshbalakrishna.in` pointing to your existing NGINX NLB hostname — the same hostname you already use for `harbor` and `dex`.

Get the NLB hostname:
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Verification

```bash
# All monitoring pods should be Running
kubectl get pods -n monitoring

# cert-manager should issue the Grafana TLS cert
kubectl get certificate grafana-tls -n monitoring

# Port-forward Prometheus UI to check scrape targets
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
# Open http://localhost:9090/targets — all targets should show green "UP"
```

Then open **`https://grafana.sudheeshbalakrishna.in`**, log in with:
- **Username:** `admin`
- **Password:** `GrafanaAdmin123!`

Go to **Dashboards → Browse** — you will find these pre-built dashboards already loaded:
- `Kubernetes / Nodes` — CPU, RAM, disk per EC2 node
- `Kubernetes / Pods` — Pod restarts, resource limits
- `NGINX Ingress Controller` — HTTP request rates, error rates, latency

> [!IMPORTANT]
> You will need to add `--set controller.metrics.enabled=true` to your NGINX Ingress install
> command (see `infra_setup.md` Step 4) so that NGINX exposes a `/metrics` endpoint for
> Prometheus to scrape. If NGINX is already running, upgrade it with the new flags.

---

## Teardown (when you want to save costs)

```bash
helm uninstall kube-prometheus-stack -n monitoring

# Delete PVCs so the EBS volumes (20Gi Prometheus + 5Gi Grafana) are destroyed.
# Skipping this will make Terraform hang when destroying the VPC.
kubectl delete pvc --all -n monitoring
kubectl delete namespace monitoring
```
