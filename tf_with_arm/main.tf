
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

# for each
module "infrastructure" {
  source = "./infrastructure"
  prefix = "tfwitharm"
}

output "cluster_info" {
    value = module.infrastructure
}

