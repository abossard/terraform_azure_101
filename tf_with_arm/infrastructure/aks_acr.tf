variable "prefix" {
  type = string
}


resource "azurerm_resource_group" "rg" {
  name     = "anbossar-tf-${var.prefix}"
  location = "westeurope"
}

resource "azurerm_template_deployment" "acsaksarm" {
  name                = "acctesttemplate-${var.prefix}"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = file("../arm/02_aks.json")

  parameters = {
    "acsName" = "acstfarm${var.prefix}"
    "aksName" = "akstfarm${var.prefix}"
  }

  deployment_mode = "Complete"
}

output "cluster_name" {
  value = azurerm_template_deployment.acsaksarm.outputs["aksName"]
}

output "registry_name" {
  value = azurerm_template_deployment.acsaksarm.outputs["acsName"]
}