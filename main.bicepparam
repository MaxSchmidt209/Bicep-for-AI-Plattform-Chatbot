// ============================================================
// main.bicepparam - Produktions-Parameter
// ============================================================
using 'main.bicep'

param location    = 'westeurope'
param prefix      = 'energy'
param environment = 'prod'

// TODO: Nach Entra ID App Registration eintragen:
param entraClientId = '<DEINE-ENTRA-APP-REGISTRATION-CLIENT-ID>'

// Wird bei Pipeline-Deployment ueberschrieben:
param imageTag = 'latest'
