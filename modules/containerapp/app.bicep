// ============================================================
// modules/containerapp/app.bicep
// Erstellt: Container App (.NET API)
//           inkl. Entra ID Auth, Managed Identity, Autoscaling
// ============================================================

param location string
param prefix string
param environment string
param acaEnvironmentId string
param managedIdentityId string
param managedIdentityClientId string
param acrLoginServer string
// Image-Tag wird bei jedem Deployment via Pipeline gesetzt
param imageTag string = 'latest'
// Entra ID App Registration fuer die API
param entraClientId string
param entraTenantId string = subscription().tenantId
// Application Insights
param appInsightsConnectionString string

// --- Container App ---
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${prefix}-api-${environment}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: acaEnvironmentId
    configuration: {
      // --- ACR Pull via Managed Identity (kein Passwort) ---
      registries: [
        {
          server: acrLoginServer
          identity: managedIdentityId
        }
      ]
      // --- Ingress: oeffentlich, HTTPS only ---
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      // --- Entra ID Authentication (Built-in ACA Auth) ---
      // Unauthentifizierte Anfragen werden mit HTTP 401 abgewiesen
    }
    template: {
      containers: [
        {
          name: '${prefix}-api'
          image: '${acrLoginServer}/${prefix}/api:${imageTag}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: managedIdentityClientId
            }
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: 'Production'
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:8080'
            }
          ]
        }
      ]
      // --- Autoscaling: min 1, max 10 Instanzen ---
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                // Neue Instanz ab 50 gleichzeitigen Requests
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// --- Entra ID Authentication (AuthConfig) ---
// Aktiviert Built-in Auth der Container App:
// Jede Anfrage ohne gueltigen Bearer-Token wird mit 401 abgewiesen
resource authConfig 'Microsoft.App/containerApps/authConfigs@2023-05-01' = {
  name: 'current'
  parent: containerApp
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'Return401'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: 'https://sts.windows.net/${entraTenantId}/'
          clientId: entraClientId
        }
        validation: {
          allowedAudiences: [
            'api://${entraClientId}'
          ]
        }
      }
    }
  }
}

// --- Outputs ---
output containerAppId string = containerApp.id
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppName string = containerApp.name
