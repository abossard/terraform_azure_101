output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "azcli_get_credentials" {
  value = "az aks get-credentials -n ${azurerm_kubernetes_cluster.aks.name} -g ${azurerm_resource_group.rg.name}"
}