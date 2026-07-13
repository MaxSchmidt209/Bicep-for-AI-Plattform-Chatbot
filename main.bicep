// ============================================================
// main.bicep - Einstiegspunkt, orchestriert alle Module
// Deployment-Reihenfolge:
//   1. monitoring  -> Log Analytics + App Insights
//   2. network     -> VNet + Subnetze + Private DNS Zones
//   3. identity    -> Managed Identity
//   4. acr         -> Container Registry + Private Endpoint + AcrPull RBAC
//   5. keyvault    -> Key Vault + Private Endpoint + Secrets User RBAC
//   6. acaEnv      -> Container Apps Environment (VNet-integriert)
//   7. acaApp      -> Container App (.NET API + Entra Auth + Scaling)
// ============================================================

targetScope = 'resourceGroup'

// --- Parameter ---
param location string = 'westeurope'
param prefix string = 'energy'
param environment string = 'prod'

// Entra ID App Registration Client ID (nach manueller Registrierung eintragen)
param entraClientId string

// Image-Tag wird beim Pipeline-Deployment ueberschrieben
param imageTag string = 'latest'

// --- 1. Monitoring ---
module monitoring 'modules/monitoring/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    prefix: prefix
    environment: environment
  }
}

// --- 2. Network ---
module network 'modules/network/vnet.bicep' = {
  name: 'network'
  params: {
    location: location
    prefix: prefix
    environment: environment
  }
}

// --- 3. Managed Identity ---
module identity 'modules/identity/managed-identity.bicep' = {
  name: 'identity'
  params: {
    location: location
    prefix: prefix
    environment: environment
  }
}

// --- 4. Azure Container Registry ---
module acr 'modules/registry/acr.bicep' = {
  name: 'acr'
  dependsOn: [ network, identity ]
  params: {
    location: location
    prefix: prefix
    environment: environment
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    acrPrivateDnsZoneId: network.outputs.acrPrivateDnsZoneId
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
  }
}

// --- 5. Key Vault ---
module keyvault 'modules/keyvault/keyvault.bicep' = {
  name: 'keyvault'
  dependsOn: [ network, identity ]
  params: {
    location: location
    prefix: prefix
    environment: environment
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    kvPrivateDnsZoneId: network.outputs.kvPrivateDnsZoneId
    managedIdentityPrincipalId: identity.outputs.managedIdentityPrincipalId
  }
}

// --- 6. Container Apps Environment ---
module acaEnvironment 'modules/containerapp/environment.bicep' = {
  name: 'acaEnvironment'
  dependsOn: [ monitoring, network ]
  params: {
    location: location
    prefix: prefix
    environment: environment
    acaSubnetId: network.outputs.acaSubnetId
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId
    logAnalyticsPrimarySharedKey: monitoring.outputs.logAnalyticsPrimarySharedKey
  }
}

// --- 7. Container App (.NET API) ---
module acaApp 'modules/containerapp/app.bicep' = {
  name: 'acaApp'
  dependsOn: [ acaEnvironment, acr, identity, monitoring ]
  params: {
    location: location
    prefix: prefix
    environment: environment
    acaEnvironmentId: acaEnvironment.outputs.acaEnvironmentId
    managedIdentityId: identity.outputs.managedIdentityId
    managedIdentityClientId: identity.outputs.managedIdentityClientId
    acrLoginServer: acr.outputs.acrLoginServer
    imageTag: imageTag
    entraClientId: entraClientId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
  }
}

// --- Outputs (wichtig fuer die Pipeline) ---
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output containerAppName string = acaApp.outputs.containerAppName
output containerAppFqdn string = acaApp.outputs.containerAppFqdn
output keyVaultName string = keyvault.outputs.keyVaultName
output keyVaultUri string = keyvault.outputs.keyVaultUri
