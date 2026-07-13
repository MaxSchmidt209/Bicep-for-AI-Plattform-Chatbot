// ============================================================
// main.bicep – Einstiegspunkt, orchestriert alle Module
// ============================================================
// TODO: Module-Aufrufe werden hier eingetragen sobald
//       die einzelnen Module befüllt sind.

targetScope = 'resourceGroup'

// --- Parameter ---
param location string = 'westeurope'
param prefix string = 'energy'
param environment string = 'prod'

// --- Module werden hier referenziert (folgen in den nächsten Schritten) ---
// module network   'modules/network/vnet.bicep'         = { ... }
// module identity  'modules/identity/managed-identity.bicep' = { ... }
// module monitoring 'modules/monitoring/monitoring.bicep' = { ... }
// module acr       'modules/registry/acr.bicep'         = { ... }
// module keyvault  'modules/keyvault/keyvault.bicep'    = { ... }
// module acaEnv    'modules/containerapp/environment.bicep' = { ... }
// module acaApp    'modules/containerapp/app.bicep'     = { ... }
