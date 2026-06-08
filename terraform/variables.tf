variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for all resources"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-aks-observability"
  description = "Name of the resource group"
}

variable "cluster_name" {
  type        = string
  default     = "aks-observability-lab"
  description = "Name of the AKS cluster"
}

variable "node_count" {
  type        = number
  default     = "1"
  description = "Number of nodes in the default node pool"
}

variable "node_vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for AKS nodes"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.35.5"
  description = "Kubernetes version for the AKS cluster"
}
