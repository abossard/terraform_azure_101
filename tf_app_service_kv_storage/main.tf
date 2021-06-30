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

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "anbossar-interview-demo"
  location = "West Europe"
}

resource "azurerm_storage_account" "storage" {
  name                     = "anbossartfstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "plan" {
  name                = "anbossarappplan"
  kind                = "Linux"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  reserved            = true
  sku {
    capacity = 1
    size     = "B2"
    tier     = "Basic"
  }
}

resource "azurerm_app_service" "app" {
  name                = "anbossartfapp2021"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  app_service_plan_id = azurerm_app_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }
  site_config {
    linux_fx_version = "DOCKER|mcr.microsoft.com/appsvc/staticsite:latest"
    always_on        = "false"
  }

  app_settings = {
    DOCKER_REGISTRY_SERVER_URL          = "https://mcr.microsoft.com"
    DOCKER_REGISTRY_SERVER_USERNAME     = ""
    DOCKER_REGISTRY_SERVER_PASSWORD     = null
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
    AzureWebJobsStorage                 = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.secret.id})"
  }
}

resource "azurerm_key_vault" "kv" {
  name                            = "anbossartfkv2"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  enable_rbac_authorization       = false
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  purge_protection_enabled        = false
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  access_policy {
    certificate_permissions = [ ]
    key_permissions = [  ]
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [ "Get", "List", "Set" ]
    storage_permissions = [  ]
    tenant_id = data.azurerm_client_config.current.tenant_id
  } 
}

resource "azurerm_key_vault_access_policy" "apol" {
  key_vault_id            = azurerm_key_vault.kv.id
  tenant_id               = azurerm_app_service.app.identity[0].tenant_id
  object_id               = azurerm_app_service.app.identity[0].principal_id
  application_id          = null
  certificate_permissions = []
  key_permissions         = []
  secret_permissions      = ["list", "get", "set"]
  storage_permissions     = []
}


resource "azurerm_key_vault_secret" "secret" {
  name         = "storageSecret"
  key_vault_id = azurerm_key_vault.kv.id
  value        = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.storage.name};AccountKey=${azurerm_storage_account.storage.secondary_access_key}"
}
