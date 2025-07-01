param webapiName string = 'jsaibackendapi'
param appServicePlanName string = 'appserviceplan'
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param rg string = ''
param webappName string = 'webapp'

@description('Location for the Static Web App')
@allowed([
  'westus2'
  'centralus'
  'eastus2'
  'westeurope'
  'eastasia'
  'eastasiastage'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param webappLocation string

@description('Id of the user or app to assign application roles')
param principalId string

// ---------------------------------------------------------------------------
// Common variables
var tags = {
  'azd-env-name': environmentName
}

// ---------------------------------------------------------------------------
// Resources

// ✅ Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(rg) ? rg : 'rg-${environmentName}'
  location: location
  tags: tags
}

// ✅ Static Web App (Frontend)
module webapp 'br/public:avm/res/web/static-site:0.7.0' = {
  name: 'webapp'
  scope: resourceGroup
  params: {
    name: webappName
    location: webappLocation
    tags: union(tags, {
      'azd-service-name': 'webapp'  // match your azure.yaml service name
    })
    sku: 'Standard'
  }
}

// ✅ App Service Plan
module serverfarm 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appserviceplan'
  scope: resourceGroup
  params: {
    name: appServicePlanName
    skuName: 'B1'
  }
}

// ✅ Web API (Backend)
module webapi 'br/public:avm/res/web/site:0.15.1' = {
  name: 'webapi'  // must match service name in azure.yaml
  scope: resourceGroup
  params: {
    kind: 'app'
    name: webapiName  // actual app name (can be different)
    tags: union(tags, {
      'azd-service-name': 'webapi'  // must match azure.yaml service name
    })
    serverFarmResourceId: serverfarm.outputs.resourceId
  }
}

// ---------------------------------------------------------------------------
// Outputs
output WEBAPP_URL string = webapp.outputs.defaultHostname
output WEBAPI_URL string = webapi.outputs.defaultHostname
