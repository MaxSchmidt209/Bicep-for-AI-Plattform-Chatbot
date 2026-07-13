// ============================================================
// modules/containerapp/environment.bicep
// Erstellt: Azure Container Apps Environment (VNet-integriert)
// ============================================================

param location string
param prefix string
param environment string
param acaSubnetId string
param logAnalyticsCustomerId string
@secure()
param logAnalyticsPrimarySharedKey string

// --- Container Apps Environment ---
resource acaEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${prefix}-acaenv-${environment}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsPrimarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: acaSubnetId
      internal: false  // Oeffentlich erreichbar (mit Entra ID Auth gesichert)
    }
    zoneRedundant: false
  }
}

// --- Outputs ---
output acaEnvironmentId string = acaEnvironment.id
output acaEnvironmentName string = acaEnvironment.name
output acaDefaultDomain string = acaEnvironment.properties.defaultDomain
