User approved the implementation plan. Now creating the prometheus-stack-values.yaml and updating infra_setup.md.

Created prometheus-stack-values.yaml

Now let me update [infra_setup.md](cci:7://file:///home/ubuntu/projects/Kubernetes_Docker_registry/infra_setup.md:0:0-0:0) with the monitoring deploy and teardown steps, and also update task.md:

Created manifest/prometheus-stack-values.yaml with exhaustive line-by-line comments explaining Grafana, Prometheus, Node Exporter, kube-state-metrics, and AlertManager.

Now I'll update [infra_setup.md](cci:7://file:///home/ubuntu/projects/Kubernetes_Docker_registry/infra_setup.md:0:0-0:0) with the monitoring steps. I need to add to the deploy section (between Step 5/Dex and Step 6/Harbor) and the teardown section, plus update the NGINX step:

Edited infra_setup.md

Both files are done. Now let me move to VERIFICATION — check the final state of the files looks correct and write the walkthrough:

Created prometheus-stack-values.yaml with full comments and updated infra_setup.md with deploy, DNS, and teardown steps for the monitoring stack.

Viewed prometheus-stack-values.yaml:1-213
Viewed infra_setup.md:64-140

Both files look perfect. Now let me write the walkthrough and update task.md:

Verified both files look correct. prometheus-stack-values.yaml has all 5 sections with thorough comments; infra_setup.md has updated NGINX step, new monitoring deploy step, updated DNS step, and updated teardown.

Created walkthrough.md
Edited task.md

All done! Here's a summary of everything that was created and what you need to do next.

---

## 📁 What Was Created

### 1. `manifest/prometheus-stack-values.yaml` ← **main new file**
A single Helm values file that configures the entire monitoring bundle. **Every single line has a comment explaining what it does and why.** The file is split into 5 clearly labelled sections:

| Section | Tool | What it is |
|---------|------|------------|
| `grafana:` | **Grafana** | The web dashboard you'll log into |
| `prometheus:` | **Prometheus** | Metric collector (scrapes every app every 15s) |
| `nodeExporter:` | **Node Exporter** | CPU/RAM/disk stats from EC2 nodes |
| `kubeStateMetrics:` | **kube-state-metrics** | Pod restart counts, replica status, etc. |
| `alertmanager:` | **AlertManager** | Alerting (installed, ready to configure later) |

### 2. `infra_setup.md` ← **updated**
- **Step 4 (NGINX)** now includes `--set controller.metrics.enabled=true` so NGINX exposes metrics Prometheus can read
- **Step 6 (new)** — full monitoring stack deploy command
- **Step 8 (DNS)** — you now need **3 CNAMEs** (Harbor, Dex, and Grafana)
- **Teardown** — monitoring stack uninstall added as Step 1

---

## 🚀 How to Deploy (3 commands)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --version 58.5.3 \
  -f manifest/prometheus-stack-values.yaml
```

## 🌐 DNS Record to Add
Create a **CNAME** for `grafana.sudheeshbalakrishna.in` pointing to your existing NLB hostname (same hostname you already use for `harbor` and `dex`).

## 🔑 Login
> URL: `https://grafana.sudheeshbalakrishna.in`  
> Username: `admin`  
> Password: `GrafanaAdmin123!`

Once inside, go to **Dashboards → Browse** and you'll find pre-built dashboards for Kubernetes Nodes, Pods, and NGINX Ingress — all populated with live data automatically. No manual wiring needed.