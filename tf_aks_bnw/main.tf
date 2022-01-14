# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
}

provider "helm" {
  debug = true

  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_admin_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_admin_config.0.cluster_ca_certificate)
  }
}

locals {
  namename                       = "${var.project-name}${var.postfix}"
  backend_address_pool_name      = "defaultaddresspool"
  frontend_port_name             = "httpPort"
  frontend_ip_configuration_name = "appGatewayFrontendIP"
  http_setting_name              = "${local.namename}-be-htst"
  listener_name                  = "${local.namename}-httplstn"
  request_routing_rule_name      = "${local.namename}-rqrt"

  aks_resource_group_name = "${local.namename}-mc"
  virtual_network_name    = "${local.namename}-aks-vnet"
  aks_subnet_name         = "${local.namename}-aks-subnet"
  appgw_subnet_name       = "appgwsubnet"

  appgw_name = "${local.namename}-appgw"

  loga_name = "${local.namename}-loga"

  public_ip_name = "${local.namename}-pup"
}

resource "azurerm_resource_group" "rg" {
  name     = local.namename
  location = "westeurope"

}
data "azurerm_resource_group" "node_rg" {
  name = azurerm_kubernetes_cluster.aks.node_resource_group
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.virtual_network_address_prefix]
}

resource "azurerm_subnet" "aks" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  name                 = local.aks_subnet_name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

resource "azurerm_subnet" "appgw" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  name                 = local.appgw_subnet_name
  address_prefixes     = [var.app_gateway_subnet_address_prefix]
}

# Public Ip 
resource "azurerm_public_ip" "public_ip" {
  name                = local.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = local.appgw_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = local.request_routing_rule_name
    http_listener_name         = local.listener_name
    rule_type                  = "Basic"
    backend_http_settings_name = local.http_setting_name
    backend_address_pool_name  = local.backend_address_pool_name
  }

  # request_routing_rule {
  # name                       = local.request_routing_rule_name
  # rule_type                  = "Basic"
  # http_listener_name         = local.listener_name
  # backend_address_pool_name  = local.backend_address_pool_name
  # backend_http_settings_name = local.http_setting_name
  # }
}
# resource "azurerm_user_assigned_identity" "agic_identity" {
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   name = "appgw-ingress-identity"
# }

# resource "azurerm_role_assignment" "ra1" {
#     scope                = data.azurerm_subnet.kubesubnet.id
#     role_definition_name = "Network Contributor"
#     principal_id         = var.aks_service_principal_object_id 

#     depends_on = [azurerm_virtual_network.test]
# }

# resource "azurerm_role_assignment" "ra2" {
#     scope                = azurerm_user_assigned_identity.testIdentity.id
#     role_definition_name = "Managed Identity Operator"
#     principal_id         = var.aks_service_principal_object_id
#     depends_on           = [azurerm_user_assigned_identity.testIdentity]
# }

# resource "azurerm_role_assignment" "ra3" {
#     scope                = azurerm_application_gateway.network.id
#     role_definition_name = "Contributor"
#     principal_id         = azurerm_user_assigned_identity.testIdentity.principal_id
#     depends_on           = [azurerm_user_assigned_identity.testIdentity, azurerm_application_gateway.network]
# }

# resource "azurerm_role_assignment" "ra4" {
#     scope                = data.azurerm_resource_group.rg.id
#     role_definition_name = "Reader"
#     principal_id         = azurerm_user_assigned_identity.testIdentity.principal_id
#     depends_on           = [azurerm_user_assigned_identity.testIdentity, azurerm_application_gateway.network]
# }

resource "azurerm_container_registry" "acr" {
  name                = "anbossartfacs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}


resource "azurerm_log_analytics_workspace" "loga" {
  name                = local.loga_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
}

# resource "azurerm_user_assigned_identity" "podidentity_user" {
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   name = "podidentity-user"
# }

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "anbossartfdemo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "anbossartfdemo"

  kubernetes_version = "1.20.9"

  role_based_access_control {
    enabled = true
    azure_active_directory {
      managed                = true
      azure_rbac_enabled     = true
      admin_group_object_ids = var.aks_admin_group_objectids
    }
  }

  default_node_pool {
    name                         = "system"
    only_critical_addons_enabled = true
    node_count                   = 3
    vm_size                      = "Standard_D2_v2"
    os_disk_size_gb              = 100
    availability_zones           = ["1", "2", "3"]
    vnet_subnet_id               = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    ingress_application_gateway {
      enabled    = true
      gateway_id = azurerm_application_gateway.appgw.id
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.loga.id
    }
  }
  network_profile {
    outbound_type = "userDefinedRouting"
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  node_resource_group = local.aks_resource_group_name

  # https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster#set-auto-upgrade-channel
  automatic_channel_upgrade = "patch"
}



resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_DS2_v2"
  mode                  = "User"
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 12
  os_disk_size_gb       = 100
  availability_zones    = ["1", "2", "3"]
  vnet_subnet_id        = azurerm_subnet.aks.id

  tags = {
    Environment = "Production"
  }
}

resource "azurerm_route_table" "default_route" {
  name                          = "default-route"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
    
  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualNetworkGateway"
  }
}


resource "azurerm_subnet_route_table_association" "add_route_to_subnet" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.default_route.id
}

resource "azurerm_role_assignment" "aks_to_acs_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "aks_to_acs_reader" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}


resource "azurerm_role_assignment" "agentpool_kubelet_msi" {
  scope                = data.azurerm_resource_group.node_rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}


resource "azurerm_role_assignment" "agentpool_kubelet_msi_main" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "agentpool_vm" {
  scope                            = data.azurerm_resource_group.node_rg.id
  role_definition_name             = "Virtual Machine Contributor"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "k8s_sa_network_contributor" {
  scope                = azurerm_virtual_network.aks_vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

resource "azurerm_role_assignment" "appgw_role_ingress" {
  scope                            = azurerm_application_gateway.appgw.id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_kubernetes_cluster.aks.addon_profile[0].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "kubernetes_cluster_role_binding" "aad_integration" {
  depends_on = [azurerm_kubernetes_cluster.aks]

  metadata {
    name = "${azurerm_kubernetes_cluster.aks.name}-admins"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "helm_release" "aad-pod-identity" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name       = "aad-pod-identity"
  repository = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart      = "aad-pod-identity"
  version    = "4.1.6"
  namespace  = "kube-system"
}

# # Allows all get list of namespaces, otherwise tools like 'kubens' won't work
# resource "kubernetes_cluster_role" "all_can_list_namespaces" {
#   depends_on = [azurerm_kubernetes_cluster.aks]
#   for_each   = true ? toset(["ad_rbac"]) : []
#   metadata {
#     name = "list-namespaces"
#   }

#   rule {
#     api_groups = ["*"]
#     resources = [
#       "namespaces"
#     ]
#     verbs = [
#       "list",
#     ]
#   }
# }



# resource "kubernetes_cluster_role_binding" "all_can_list_namespaces" {
#   depends_on = [azurerm_kubernetes_cluster.aks]
#   for_each   = true ? toset(["ad_rbac"]) : []
#   metadata {
#     name = "authenticated-can-list-namespaces"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.all_can_list_namespaces[each.key].metadata.0.name
#   }

#   subject {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "Group"
#     name      = "system:authenticated"
#   }
# }


