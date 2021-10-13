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
variable "project-name" {
  description = "Funny name this all belongs to"
  default = "megusta"
}

variable "postfix" {
  description = "Randon stuff to add everywhere"
  default = "-an12"
}

variable "location" {
    description = "Location of the cluster."
    default = "westeurope"
}

variable "virtual_network_address_prefix" {
    description = "VNET address prefix"
    default     = "15.0.0.0/8"
}

variable "aks_subnet_address_prefix" {
    description = "Subnet address prefix."
    default     = "15.0.0.0/16"
}

variable "app_gateway_subnet_address_prefix" {
    description = "Subnet server IP address."
    default     = "15.1.0.0/16"
}

variable "aks_name" {
    description = "AKS cluster name"
    default     = "aks-cluster1"
}

variable "aks_service_cidr" {
    description = "CIDR notation IP range from which to assign service cluster IPs"
    default     = "10.0.0.0/16"
}

variable "aks_dns_service_ip" {
    description = "DNS server IP address"
    default     = "10.0.0.10"
}

locals {
  namename = "${var.project-name}${var.postfix}"
  backend_address_pool_name      = "defaultaddresspool"
  frontend_port_name             = "httpPort"
  frontend_ip_configuration_name = "appGatewayFrontendIP"
  http_setting_name              = "${local.namename}-be-htst"
  listener_name                  = "${local.namename}-httplstn"
  request_routing_rule_name      = "${local.namename}-rqrt"

  virtual_network_name = "${local.namename}-aks-vnet"
  aks_subnet_name = "${local.namename}-aks-subnet"
  appgw_subnet_name = "appgwsubnet"
  
  appgw_name = "${local.namename}-appgw"

  loga_name = "${local.namename}-loga"

  public_ip_name = "${local.namename}-pup"
}

resource "azurerm_resource_group" "rg" {
  name     = local.namename
  location = "westeurope"
}

resource "azurerm_virtual_network" "aks_vnet" {
    name                = local.virtual_network_name
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = [var.virtual_network_address_prefix]
}

resource "azurerm_subnet" "aks" {
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  name           = local.aks_subnet_name
  address_prefixes = [var.aks_subnet_address_prefix]
}

resource "azurerm_subnet" "appgw" {
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  name           = local.appgw_subnet_name
  address_prefixes = [var.app_gateway_subnet_address_prefix]
}

# Public Ip 
resource "azurerm_public_ip" "public_ip" {
    name                         = local.public_ip_name
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Static"
    sku                          = "Standard"
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
      name = local.request_routing_rule_name
      http_listener_name = local.listener_name
      rule_type                  = "Basic"
      backend_http_settings_name = local.http_setting_name
      backend_address_pool_name = local.backend_address_pool_name
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
  name                     = "anbossartfacs"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Basic"
  admin_enabled            = false
}


resource "azurerm_log_analytics_workspace" "loga" {
  name                = local.loga_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "anbossartfdemo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "anbossartfdemo"

  default_node_pool {
    name       = "default"
    node_count = 3
    enable_auto_scaling = true
    min_count = 1
    max_count = 12
    vm_size    = "Standard_D2_v2"
    os_disk_size_gb = 100
    availability_zones = [ "1", "2", "3" ]
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    ingress_application_gateway {
      enabled = true
      gateway_id = azurerm_application_gateway.appgw.id
      gateway_name = azurerm_application_gateway.appgw.name
    }
    oms_agent {
      enabled = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.loga.id
    }
  }
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }
  
}

resource "azurerm_role_assignment" "aks_to_acs" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}