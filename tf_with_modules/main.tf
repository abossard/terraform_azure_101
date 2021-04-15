module "infrastructure" {
  source = "./infrastructure"
  prefix = "demo2"
}

locals {
    cluster_name = module.infrastructure.cluster_name
    registry_name = module.infrastructure.registry_name
}

output "cluster_name" {
    value = local.cluster_name
}

output "registry_name" {
    value = local.registry_name
}