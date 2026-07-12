# Azure AKS Observability Stack

A production-grade Kubernetes observability stack built on AKS, Prometheus,
Grafana, and custom Python instrumentation.

Part of the **Maselli Technologies SRE Training Curriculum** — Month 3 of 6.

---

## What This Project Does

Deploys a fully instrumented observability stack on Azure Kubernetes Service:

- **AKS cluster** provisioned via Terraform with Log Analytics integration
- **Prometheus + Grafana + Alertmanager** deployed via Helm (kube-prometheus-stack)
- **Alerting rules as code** via PrometheusRule Kubernetes manifests
- **Custom application metrics** exposed via Python prometheus_client library
- **End-to-end scraping pipeline** via ServiceMonitor custom resources

---

## Architecture

```
Custom Python App (FastAPI)
        │
        │ /metrics endpoint
        ▼
ServiceMonitor (Kubernetes CRD)
        │
        │ tells Prometheus operator to scrape
        ▼
Prometheus (in-cluster)
        │
        ├── Evaluates PrometheusRule alerts
        │   └── NodeHighCPU, NodeHighMemory, PodNotRunning
        │
        └── Data source for Grafana
                │
                ├── AKS Cluster Health Dashboard
                │   └── Running pods, CPU %, Memory %
                │
                └── Application Performance Dashboard
                    └── Request rate, Error rate %, p95 latency
```
----

## SRE Skills Demonstrated

| Skill | Implementation |
|-------|---------------|
| Kubernetes | AKS cluster, Deployments, Services, namespaces |
| Helm | kube-prometheus-stack deployment and configuration |
| PromQL | rate(), histogram_quantile(), absent(), aggregations |
| Alerting as code | PrometheusRule manifests, pending windows, absent() |
| App instrumentation | prometheus_client Counter, Histogram, /metrics endpoint |
| Operator pattern | ServiceMonitor CRDs, Prometheus operator auto-configuration |
| IaC | Terraform for AKS, ACR, Log Analytics, role assignments |
| Container registry | ACR provisioned via Terraform, AcrPull role assignment to AKS |

---

## Key Lessons Learned

**The missing series problem** — alerting on `metric == 0` fails when the
metric series disappears entirely. Use `absent()` to detect missing series.
See TROUBLESHOOTING.md Issue 5.

**rate() window sizing** — too short a window gives noisy results with sparse
traffic. Match the window to your traffic patterns.

**Operator pattern** — PrometheusRule and ServiceMonitor manifests are picked
up automatically by the Prometheus operator. No config file editing required.

---

## Project Structure

```
azure-aks-observability/
├── terraform/           # AKS cluster, ACR, Log Analytics, role assignments
├── k8s/
│   ├── test-deployment.yaml      # nginx test workload
│   ├── prometheus-rules.yaml     # PrometheusRule alerting rules
│   └── metrics-app.yaml          # App deployment, service, ServiceMonitor
├── app/
│   ├── app.py                    # FastAPI app with prometheus_client instrumentation
│   └── Dockerfile
├── TROUBLESHOOTING.md            # Post-mortem style issue log
└── README.md
```

---

## Startup Sequence (after terraform destroy)

```powershell
terraform apply -auto-approve
az aks get-credentials --resource-group rg-aks-observability --name aks-observability-lab --overwrite-existing
kubectl get nodes
helm install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set grafana.adminPassword="<GRAFANA_ADMIN_PASSWORD>" `
  --set prometheus.prometheusSpec.retention="24h" `
  --set alertmanager.enabled=true
kubectl apply -f k8s/
```

Store `GRAFANA_ADMIN_PASSWORD` in your local `.env` file. Do not commit it.

---

## Part of the Maselli Technologies SRE Training Curriculum

| Month | Project | Focus | Status |
|-------|---------|-------|--------|
| 1 | Azure SLO Dashboard + AI Explainer | SLIs, SLOs, Error Budgets, AIOps | ✅ Complete |
| 2 | AI-Powered Incident Response Bot | Incident Management, Runbooks, Auto-Remediation | ✅ Complete |
| 3 | AKS Observability Stack | Kubernetes, Prometheus, Grafana | ✅ Complete |
| 4 | GitOps Continuous Delivery with Argo CD | GitOps, Declarative Delivery, AKS | ✅ Complete |
| 5 | Chaos Engineering Suite | Chaos Engineering, Resilience | ⏳ Planned |
| 6 | Full SRE Platform + AI Ops Chatbot | Capstone Integration | ⏳ Planned |
