# Prometheus Stack — Helm Install Reference

## Chart
prometheus-community/kube-prometheus-stack

## Install Command
```powershell
helm install prometheus prometheus-community/kube-prometheus-stack `
  --namespace monitoring `
  --set grafana.adminPassword="<GRAFANA_ADMIN_PASSWORD>" `
  --set prometheus.prometheusSpec.retention="24h" `
  --set alertmanager.enabled=true

## Credentials
Grafana admin password is set at install time via `--set grafana.adminPassword`.
Use a strong password and store it in your `.env` file locally.
Do not commit the actual password to this repository.
```

## Verify
```powershell
kubectl get pods -n monitoring
```

## Access Prometheus UI
```powershell
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```
Then open http://localhost:9090

## Access Grafana UI
```powershell
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```
Then open http://localhost:3000
Credentials: admin / <GRAFANA_ADMIN_PASSWORD>