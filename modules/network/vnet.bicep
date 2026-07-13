// ============================================================
// modules/network/vnet.bicep
// Erstellt: VNet + Subnetze fuer ACA und Private Endpoints
// ============================================================

param location string
param prefix string
param environment string

// --- Virtual Network ---
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${prefix}-vnet-${environment}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        // Subnet fuer Azure Container Apps Environment (mind. /23)
        name: 'snet-aca'
        properties: {
          addressPrefix: '10.0.0.0/23'
          // Delegierung fuer Container Apps
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        // Subnet fuer Private Endpoints (ACR, Key Vault)
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// --- Private DNS Zone fuer ACR ---
resource acrDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

resource acrDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${prefix}-acr-dnslink-${environment}'
  parent: acrDnsZone
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

// --- Private DNS Zone fuer Key Vault ---
resource kvDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource kvDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${prefix}-kv-dnslink-${environment}'
  parent: kvDnsZone
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

// --- Outputs ---
output vnetId string = vnet.id
output acaSubnetId string = vnet.properties.subnets[0].id
output privateEndpointSubnetId string = vnet.properties.subnets[1].id
output acrPrivateDnsZoneId string = acrDnsZone.id
output kvPrivateDnsZoneId string = kvDnsZone.id
