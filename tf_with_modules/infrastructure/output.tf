
output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "registry_name" {
  value = azurerm_container_registry.acr.name
}