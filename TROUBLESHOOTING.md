# Troubleshooting Log — azure-aks-observability

Post-mortem style log of issues encountered during the initial build and deployment.
Each entry follows the SRE format: **symptom → root cause → resolution**.

---

## Issue 1 — enable_auto_scaling syntax error in Terraform

**Date:** 2026-06-07
**Severity:** Low
**Phase:** Phase 1 — AKS cluster provisioning

### Symptom
`terraform init` failed with:
`Error: Argument or block definition required`
on `main.tf` line 40, referencing `enable_auto_scaling - false`.

### Root Cause
The argument was written with a dash instead of an equals sign
(`enable_auto_scaling - false` instead of `enable_auto_scaling = false`).
Additionally, `enable_auto_scaling` is not a valid standalone argument in the
AzureRM 4.x provider's `default_node_pool` block. When autoscaling is not
configured, the argument should be omitted entirely rather than set to false.

### Resolution
Removed the `enable_auto_scaling` line entirely from the `default_node_pool`
block. Autoscaling is disabled by default when the argument is absent.

### Prevention
When omitting optional boolean flags in Terraform, leave them out rather than
explicitly setting them to false. Read the provider documentation for the exact
version in use — argument names and defaults change between major provider versions.

---

## Issue 2 — Kubernetes version LTS restriction on AKS

**Date:** 2026-06-07
**Severity:** Medium
**Phase:** Phase 1 — AKS cluster provisioning

### Symptom
`terraform apply` failed with `K8sVersionNotSupported` error:
`Managed cluster aks-observability-lab is on version 1.30.14, which is only
available for Long-Term Support (LTS). If you intend to onboard to LTS, please
ensure the cluster is in Premium tier.`

Same error repeated when version was changed to 1.31.

### Root Cause
Azure has migrated older Kubernetes versions (1.30, 1.31, 1.32) to LTS-only
support, requiring a Premium tier AKS cluster to use them. Our Terraform config
specified `sku_tier = "Free"` (the default), which is incompatible with LTS
versions. The `az aks get-versions` command output only showed major versions
(1.30, 1.31, 1.32...) without indicating which patch versions were LTS-locked.

### Resolution
Ran `az aks get-versions --location eastus --output table` to get the full
version list including SupportPlan column. Selected version `1.35.5` which
shows `KubernetesOfficial, AKSLongTermSupport` — meaning it supports both
standard and LTS tiers. Updated `variables.tf` default to `1.35.5`.

### Prevention
Always query available versions with the full output table before specifying
a Kubernetes version in Terraform. The SupportPlan column determines tier
compatibility. Versions showing only `AKSLongTermSupport` require Premium tier.

---

## Issue 3 — Standard_B2s VM size not available in subscription

**Date:** 2026-06-07
**Severity:** Medium
**Phase:** Phase 1 — AKS cluster provisioning

### Symptom
`terraform apply` failed with `BadRequest` error:
`The VM size of Standard_B2s is not allowed in your subscription in location
'eastus'.`

### Root Cause
The Azure Training subscription has restrictions on which VM families are
available. The B-series burstable VMs (Standard_B2s) are not permitted in this
subscription type in East US, despite the subscription having 10 vCPUs of
Standard BS Family quota showing as available. This is the same class of
subscription restriction encountered in Month 1 with App Service Plans.

### Resolution
Read the allowed VM sizes from the error message and selected `Standard_D2s_v3`
— 2 vCPUs, 8GB RAM, broadly available across subscription types, well supported
by AKS. Updated `node_vm_size` default in `variables.tf`.

### Prevention
Before specifying a VM size for AKS node pools on a new subscription, verify
availability with:
`az vm list-skus --location eastus --size Standard_B --output table`
The quota check (`az vm list-usage`) shows vCPU limits but does not indicate
whether a specific SKU is permitted in your subscription type.

---

## Issue 4 — Terraform state drift from AKS auto-applied upgrade_settings

**Date:** 2026-06-07
**Severity:** Low
**Phase:** Phase 1 — Post-deployment cleanup

### Symptom
After removing the hardcoded `subscription_id` from `providers.tf`, `terraform
plan` showed one pending change — removal of `upgrade_settings` from the
`default_node_pool` block — even though no infrastructure changes were intended.

### Root Cause
AKS automatically applies default `upgrade_settings` (max_surge: 10%) to node
pools at provisioning time. Our Terraform config did not define this block, so
Terraform detected drift between the config and the actual infrastructure state.

### Resolution
Added an explicit `upgrade_settings` block to `default_node_pool` in `main.tf`:
```hcl
upgrade_settings {
  max_surge = "10%"
}
```
`terraform plan` then showed `No changes.`

### Prevention
After initial provisioning, always run `terraform plan` and review any drift
before committing code. Azure services often auto-apply defaults that aren't
in your Terraform config, causing state drift that should be explicitly locked in.

## Issue 5 — PodNotRunning alert failed to fire when deployment was deleted

**Date:** 2026-06-14
**Severity:** Medium
**Phase:** Phase 3 — Prometheus alerting rules

### Symptom
Deleted the nginx-test deployment to trigger the PodNotRunning alert. Alert
remained Inactive despite no pods running in the default namespace.

### Root Cause
The original alert expression was:
`kube_pod_status_phase{namespace="default", phase="Running"} == 0`
When a deployment is deleted entirely, kube-state-metrics stops exporting
the metric series for those pods. There is no series with value 0 — there
is no series at all. A PromQL expression that filters on a non-existent
series returns empty, not false, so the alert never evaluates to true.

### Resolution
Replaced the expression with absent():
`absent(kube_pod_status_phase{namespace="default", phase="Running"})`
absent() returns 1 when the metric series does not exist, correctly
detecting both crashed pods and fully deleted deployments.

### Prevention
When writing alerts for workload presence, always use absent() rather than
== 0. Reserve == 0 for metrics that always exist but report a zero value
(counters, gauges). Use absent() when the series itself may disappear.