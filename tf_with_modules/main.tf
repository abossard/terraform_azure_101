
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
module "infrastructure" {
  source = "./infrastructure"
  for_each = toset(["demo2", "demo3"])
  prefix = each.key
}

#locals {
#    cluster_name = module.infrastructure[0].cluster_name
#    registry_name = module.infrastructure[0].registry_name
#}

output "cluster_name" {
    value = module.infrastructure
}

#output "registry_name" {
#    value = local.registry_name
#}