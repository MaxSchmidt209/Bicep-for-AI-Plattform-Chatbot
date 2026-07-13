# Bicep Infrastructure – AI Platform Chatbot (Energy Management API)

Dieses Repository enthält die gesamte Azure-Infrastruktur als Bicep-Templates für die Energiemanagement-API mit AI-Chatbot-Anbindung.

## Struktur

```
.
├── main.bicep                  # Einstiegspunkt – orchestriert alle Module
├── main.bicepparam             # Parameter für die Produktion
├── modules/
│   ├── network/
│   │   └── vnet.bicep          # VNet + Subnetze
│   ├── registry/
│   │   └── acr.bicep           # Azure Container Registry + Private Endpoint
│   ├── identity/
│   │   └── managed-identity.bicep  # User-assigned Managed Identities
│   ├── keyvault/
│   │   └── keyvault.bicep      # Key Vault + Private Endpoint + RBAC
│   ├── containerapp/
│   │   ├── environment.bicep   # Container Apps Environment (VNet-integriert)
│   │   └── app.bicep           # Container App (.NET API)
│   └── monitoring/
│       └── monitoring.bicep    # Log Analytics Workspace + Application Insights
└── .github/
    └── workflows/
        └── deploy.yml          # (Platzhalter) Azure DevOps / GitHub Actions Hinweis
```

## Deployment

```bash
# Login
az login
az account set --subscription "<subscription-id>"

# Ressource Group erstellen
az group create --name rg-energy-prod --location westeurope

# Deployment starten
az deployment group create \
  --resource-group rg-energy-prod \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Module

| Modul | Datei | Beschreibung |
|---|---|---|
| Network | `modules/network/vnet.bicep` | VNet mit Subnetzen für ACA und Private Endpoints |
| Registry | `modules/registry/acr.bicep` | Azure Container Registry (Premium) mit Private Endpoint |
| Identity | `modules/identity/managed-identity.bicep` | Managed Identities für ACA |
| Key Vault | `modules/keyvault/keyvault.bicep` | Key Vault mit Private Endpoint und RBAC |
| Container App Env | `modules/containerapp/environment.bicep` | ACA Environment, VNet-integriert |
| Container App | `modules/containerapp/app.bicep` | Die .NET API als Container App |
| Monitoring | `modules/monitoring/monitoring.bicep` | Log Analytics + Application Insights |
