@description('')
param appServiceName string = 'anbossarapp'

@description('')
param kvName string = 'anbossarkv'

@description('')
param storageName string = 'anbossarstor'

var postfix = toLower(take(base64(resourceGroup().id), 3))
var resourceNames = {
  AppService: concat(appServiceName, postfix)
  AppServicePlan: '${appServiceName}plan${postfix}'
  StorageAccount: concat(storageName, postfix)
  KeyVault: concat(kvName, postfix)
  KeyVaultSecretsConnectionString: 'anbossarStorageConnectionString'
}
var resourceVersions = {
  KeyVault: '2019-09-01'
  AppService: '2020-12-01'
  AppServicePlan: '2020-12-01'
  StorageAccount: '2021-01-01'
}

resource resourceNames_KeyVault 'Microsoft.KeyVault/vaults@[variables(\'resourceVersions\').KeyVault]' = {
  name: resourceNames.KeyVault
  location: resourceGroup().location
  properties: {
    enableRbacAuthorization: false
    enableSoftDelete: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: reference(resourceNames.AppService, resourceVersions.AppService, 'Full').identity.tenantId
        objectId: reference(resourceNames.AppService, resourceVersions.AppService, 'Full').identity.principalId
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
      name: 'Standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
  dependsOn: [
    resourceNames_AppService
  ]
}

resource resourceNames_KeyVault_resourceNames_KeyVaultSecretsConnectionString 'Microsoft.KeyVault/vaults/secrets@[variables(\'resourceVersions\').KeyVault]' = {
  name: '${resourceNames.KeyVault}/${resourceNames.KeyVaultSecretsConnectionString}'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${resourceNames.StorageAccount};AccountKey=${listKeys(resourceNames.StorageAccount, resourceVersions.StorageAccount).keys[0].value}'
  }
  dependsOn: [
    resourceNames_KeyVault
    resourceNames_StorageAccount
  ]
}

resource resourceNames_StorageAccount 'Microsoft.Storage/storageAccounts@[variables(\'resourceVersions\').StorageAccount]' = {
  name: resourceNames.StorageAccount
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource resourceNames_AppServicePlan 'Microsoft.Web/serverfarms@[variables(\'resourceVersions\').AppServicePlan]' = {
  name: resourceNames.AppServicePlan
  kind: 'linux'
  location: resourceGroup().location
  tags: {}
  properties: {
    name: resourceNames.AppServicePlan
    workerSize: 1
    reserved: true
    numberOfWorkers: 1
  }
  sku: {
    name: 'B2'
    tier: 'Basic'
    size: 'B2'
    family: 'B'
    capacity: 1
  }
  dependsOn: []
}

resource resourceNames_AppService 'Microsoft.Web/sites@[variables(\'resourceVersions\').AppService]' = {
  name: resourceNames.AppService
  identity: {
    type: 'SystemAssigned'
  }
  location: resourceGroup().location
  tags: {}
  properties: {
    name: resourceNames.AppService
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
      alwaysOn: 'false'
    }
    serverFarmId: resourceNames_AppServicePlan.id
    clientAffinityEnabled: false
  }
}

resource resourceNames_AppService_appsettings 'Microsoft.Web/sites/config@[variables(\'resourceVersions\').AppService]' = {
  name: '${resourceNames.AppService}/appsettings'
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${resourceNames_KeyVault_resourceNames_KeyVaultSecretsConnectionString.properties.secretUriWithVersion})'
  }
  dependsOn: [
    resourceNames_AppService
  ]
}
