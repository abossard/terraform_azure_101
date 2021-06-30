var targetNames = [
  'QA'
  'Demo'
]

module myModule 'appservice.bicep' = {
  name: 'myModuleDeployment'
  params: {
    environmentType: 'prod'
  }
}

output prodUrl string = myModule.outputs.url

@batchSize(10)
module appService 'appservice.bicep' = [for name in targetNames: if(length(name) > 2){
  name: 'appService${name}'
  params: {
    environmentType: 'nonprod'
    prefix: '${toLower(name)}'
    customTags: {
      tier: '${toLower(name)}'
    }
  }
}]

output appServiceUrls array = [for (name, i) in targetNames: {
  name: name
  url: appService[i].outputs.url
}]
