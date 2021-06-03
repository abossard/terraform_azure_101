# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_container_registry" "acr" {
  name                     = "anbossartfacs"
  resource_group_name      = azurerm_resource_group.rg[count.index].name
  location                 = azurerm_resource_group.rg[count.index].location
  sku                      = "Basic"
  admin_enabled            = false
  count = 3
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "anbossartfdemo"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  dns_prefix          = "anbossartfdemo"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    os_disk_size_gb = 100
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_to_acs" {
  scope                = azurerm_container_registry.acr[count.index].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  count = 3
}

resource "azurerm_resource_group" "rg" {
  name     = "anbossar-tf-demo-${count.index}"
  location = "westeurope"
  count = 3
}
