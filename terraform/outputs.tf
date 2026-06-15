output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.aks.name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster API server"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.acr.login_server
}