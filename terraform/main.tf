# Resource Group setup
resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    project     = "maselli-sre-month3"
    environment = "lab"
    managed_by  = "terraform"
  }
}

# Log Analytics Workspace setup
# AKS will use this for the container logs and monitoring
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-aks-observability"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = azurerm_resource_group.aks.tags
}

# AKS Cluster setup
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "maselli-aks"
  kubernetes_version  = var.kubernetes_version

  # The default node pool setup - Single node for cost control in a lab
  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Use a system-assigned managed identity
  # This replaces a service principal authentication for the AKS
  identity {
    type = "SystemAssigned"
  }

  # Connect the AKS to the Log Analytics Workspace for monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  # Network configuration setup
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  tags = azurerm_resource_group.aks.tags
}

# Azure Container Registry
# Used to store the custom metrics app image
resource "azurerm_container_registry" "acr" {
  name                = "maselliaksacr"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = azurerm_resource_group.aks.tags
}

# Grant AKS permission to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}