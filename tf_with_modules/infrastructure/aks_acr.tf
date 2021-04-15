variable "prefix" {
  type = string
}

variable "commonTags" {
  value = {
    "demo" = "terraform"
  }
}


resource "azurerm_resource_group" "rg" {
  name     = "anbossar-tf-${var.prefix}"
  location = "westeurope"
  tags = var.commonTags
}

resource "azurerm_container_registry" "acr" {
  name                     = "anbossartfacs${var.prefix}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Basic"
  admin_enabled            = false
  tags = var.commonTags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "anbossartf${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "anbossartf${var.prefix}"
  tags = var.commonTags

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_to_acs" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "registry_name" {
  value = azurerm_container_registry.acr.name
}