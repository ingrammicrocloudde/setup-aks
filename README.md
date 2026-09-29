# Setup AKS – DEV Environment

Dieses Repository stellt ein Azure Kubernetes Service (AKS) Cluster im **DEV-Tier** bereit.  
Die Konfiguration ist auf Entwicklungsumgebungen ausgelegt: günstiger VM-Typ, einzelner Node, kostenloser AKS-SKU-Tier.

---

## Deploy to Azure

Klicke auf den Button, um das Cluster direkt im Azure Portal bereitzustellen:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fingrammicrocloudde%2Fsetup-aks%2Fmain%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fingrammicrocloudde%2Fsetup-aks%2Fmain%2Fazuredeploy.json)

---

## Parameter

| Parameter | Standard | Beschreibung |
|---|---|---|
| `clusterName` | `aks-dev` | Name des AKS-Clusters |
| `location` | *(Resource-Group-Region)* | Azure-Region |
| `nodeCount` | `1` | Anzahl der Nodes |
| `nodeVmSize` | `Standard_B2ms` | VM-Größe |
| `osDiskSizeGB` | `32` | OS-Disk-Größe in GB |
| `enableAutoScaling` | `false` | Autoscaler aktivieren |
| `minNodeCount` | `1` | Min. Nodes (Autoscaler) |
| `maxNodeCount` | `3` | Max. Nodes (Autoscaler) |
| `networkPlugin` | `kubenet` | Netzwerk-Plugin (`kubenet` oder `azure`) |
| `enableRbac` | `true` | Kubernetes RBAC aktivieren |
| `enableAzureMonitor` | `false` | Container Insights aktivieren |

Die Kubernetes-Version wird nicht fest vorgegeben: AKS wählt beim Erstellen eine in der gewählten Region unterstützte Standardversion. Für ein bereits vorhandenes Cluster mit einer nicht mehr unterstützten Version ist stattdessen ein Upgrade nötig; prüfe die verfügbaren Versionen mit `az aks get-versions --location <region>` und die Upgrade-Möglichkeiten mit `az aks get-upgrades --resource-group <resource-group> --name <cluster-name>`.

---

## DEV-Tier Eigenschaften

- **SKU-Tier**: `Free` (kein SLA für den Control Plane)
- **Node Pool**: `Standard_B2ms` – kosteneffizient für Entwicklung
- **Node-Anzahl**: 1 (skalierbar bis 5)
- **Autoscaler**: deaktiviert (kann aktiviert werden)
- **Monitoring**: Container Insights deaktiviert (spart Kosten)
- **Identity**: SystemAssigned Managed Identity

---

## Voraussetzungen

- Azure-Subscription mit ausreichenden Berechtigungen (`Contributor` auf der Resource Group)
- Resource Group muss vor dem Deployment existieren

---

## Deployment per Azure CLI

```bash
# Resource Group anlegen
az group create \
  --name rg-aks-dev \
  --location germanywestcentral

# Deployment starten
az deployment group create \
  --resource-group rg-aks-dev \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.dev.json

# kubeconfig herunterladen
az aks get-credentials \
  --resource-group rg-aks-dev \
  --name aks-dev \
  --overwrite-existing
```

---

## Ressourcen

- [AKS Dokumentation](https://learn.microsoft.com/azure/aks/)
- [ARM Template Referenz – ManagedClusters](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters)
- [AKS Free Tier](https://learn.microsoft.com/azure/aks/free-standard-pricing-tiers)
