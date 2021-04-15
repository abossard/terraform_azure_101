
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
module "infrastructuremap" {
  source = "./infrastructure"
  for_each = {
    cluster2 = "demo2"
    cluster3 = "demo3"
  }
  prefix = "${each.key}${each.value}"
}

output "cluster_name" {
    value = module.infrastructuremap
}


module "infrastructurecount" {
  source = "./infrastructure"
  count = 2
  prefix = "demo${count.index%2 == 0 ? "even" : "odd"}${count.index + 4}"
}

output "cluster_name_2" {
    value = module.infrastructurecount
}
