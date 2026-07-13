// ============================================================
// modules/identity/managed-identity.bicep
// Erstellt: User-assigned Managed Identity
// RBAC-Zuweisungen erfolgen in acr.bicep und keyvault.bicep
// direkt bei den jeweiligen Ressourcen (Best Practice)
// ============================================================

param location string
param prefix string
param environment string

// --- User-assigned Managed Identity fuer die Container App ---
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}-mi-${environment}'
  location: location
}

// --- Outputs ---
output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
