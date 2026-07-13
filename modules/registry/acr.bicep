// ============================================================
// modules/registry/acr.bicep
// Erstellt: Azure Container Registry (Premium) +
//           Private Endpoint + AcrPull RBAC fuer Managed Identity
// ============================================================

param location string
param prefix string
param environment string
param privateEndpointSubnetId string
param acrPrivateDnsZoneId string
param managedIdentityPrincipalId string

// --- Azure Container Registry (Premium fuer Private Endpoint) ---
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${prefix}acr${environment}'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false  // Kein Admin-User – nur Managed Identity
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

// --- Private Endpoint fuer ACR ---
resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${prefix}-pe-acr-${environment}'
  location: location
  properties: {
    subnet: { id: privateEndpointSubnetId }
    privateLinkServiceConnections: [
      {
        name: '${prefix}-plsc-acr-${environment}'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [ 'registry' ]
        }
      }
    ]
  }
}

// --- DNS Zone Group fuer ACR Private Endpoint ---
resource acrDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: 'acrDnsZoneGroup'
  parent: acrPrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: { privateDnsZoneId: acrPrivateDnsZoneId }
      }
    ]
  }
}

// --- RBAC: AcrPull fuer Managed Identity ---
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentityPrincipalId, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// --- Outputs ---
output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
