@allowed([
  'nonprod'
  'prod'
])
@description('The name of the environment. This must be nonprod or prod.')
param environmentType string = 'nonprod'

param location string = resourceGroup().location

param useCustomTags bool = true
param deploySecret bool = true

@minLength(1)
@maxLength(24)
param prefix string = 'anbobiceps'

param customTags object = {
  tier: 'demo'
}

var postfix = take(uniqueString(resourceGroup().id), 3)
var tags = union( useCustomTags ? customTags: {}, {
  env: environmentType
  prefix: prefix
})
var keyVaultPlan = environmentType == 'prod' ? 'premium' : 'standard'
var resourceNames = {
  AppService: '${prefix}app${postfix}'
  AppServicePlan: '${prefix}plan${postfix}'
  StorageAccount: '${prefix}stor${postfix}'
  KeyVault: '${prefix}kv${postfix}'
  KeyVaultSecretsConnectionString: '${prefix}secretstring${postfix}'
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: resourceNames.KeyVault
  location: location
  tags: tags
  properties: {
    enableSoftDelete: false
    enableRbacAuthorization: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: appService.identity.tenantId
        objectId: appService.identity.principalId
        permissions: {
          secrets: [
            'list'
            'get'
            'set'
          ]
        }
      }
    ]
    sku: {
      name: keyVaultPlan
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = if(deploySecret) {
  parent: keyVault
  tags: tags
  name: resourceNames.KeyVaultSecretsConnectionString
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.name, storage.apiVersion).keys[0].value}'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: resourceNames.StorageAccount
  tags: tags
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {}
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: resourceNames.AppServicePlan
  location: location
  kind: 'linux'
  tags: tags
  properties: {
    reserved: true
  }
  sku: {
    name: 'B2'
    tier: 'Basic'
    size: 'B2'
    family: 'B'
    capacity: 1
  }
}

resource appService 'Microsoft.Web/sites@2021-01-01' = {
  name: resourceNames.AppService
  identity: {
    type: 'SystemAssigned'
  }
  location: location
  tags: tags
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://mcr.microsoft.com'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: null
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      appCommandLine: ''
      alwaysOn: false
    }
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
  }
  resource config 'config' = if(deploySecret) {
    name: 'appsettings'
    properties: {
      AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${reference(secret.name).secretUriWithVersion}'
    }
  }
}

output url string = 'https://${reference(appService.name).defaultHostName}'
output secretId string = deploySecret ? secret.id : ''
