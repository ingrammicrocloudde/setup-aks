# Setup AKS – DEV Environment

Dieses Repository stellt ein Azure Kubernetes Service (AKS) Cluster im **DEV-Tier** bereit.  
Die Konfiguration ist auf Entwicklungsumgebungen ausgelegt: günstiger VM-Typ, einzelner Node, kostenloser AKS-SKU-Tier.

## NOOBS Quickstart (3 Schritte)

1. Klicke auf den ersten Deploy-Button und deploye das AKS-Cluster mit den Standardwerten.
2. Klicke auf den zweiten Deploy-Button für die WebApp.
3. Gib dort diese beiden Pflichtwerte ein:
  - `aksClusterName`: derselbe Name wie aus Schritt 1 (Standard: `aks-dev`)
  - `webappImage`: dein echtes Container-Image (Beispiel: `myacr.azurecr.io/aks-learn-webapp:v1`)

Danach wird die WebApp automatisch per GitOps in das vorhandene AKS ausgerollt.

---

## Deploy to Azure

Klicke auf den Button, um das Cluster direkt im Azure Portal bereitzustellen:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fingrammicrocloudde%2Fsetup-aks%2Fmain%2Fazuredeploy.json)

Optional: WebApp (GitOps/Flux) auf ein bereits vorhandenes AKS-Cluster deployen:

[![Deploy WebApp to existing AKS](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fingrammicrocloudde%2Fsetup-aks%2Fmain%2Fazuredeploy.webapp.json)

Hinweis für NOOBS: Dieser Button fragt direkt das gewünschte Container-Image ab (z. B. `myacr.azurecr.io/aks-learn-webapp:v1`). Ein manuelles Editieren von `webapp/k8s/deployment.yaml` ist dafür nicht nötig.
Wichtig: Bei `aksClusterName` den gleichen AKS-Namen wie im ersten Button verwenden (Standard: `aks-dev`).

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

## Standard-Tier Eigenschaften

- **SKU-Tier**: `Standard` (SLA für den Control Plane)
- **Node Pool**: flexibel nach Workload, z. B. `Standard_D2s_v3` oder höher
- **Node-Anzahl**: für HA i. d. R. mindestens 2 Nodes pro Pool
- **Autoscaler**: empfohlen für Lastspitzen und Kostenoptimierung
- **Monitoring**: Container Insights empfohlen für Betrieb und Troubleshooting
- **Einsatz**: geeignet für produktionsnahe Umgebungen mit höheren Verfügbarkeitsanforderungen

## Premium-Tier Eigenschaften

- **SKU-Tier**: `Premium` (enthält zusätzlich Long Term Support (LTS) für Kubernetes-Versionen)
- **Support-Lebenszyklus**: längere Unterstützung je Kubernetes-Version für planbare Enterprise-Upgrades
- **Node Pool**: ähnlich wie Standard, aber typischerweise mit produktionsreifen VM-Größen und HA-Design
- **Node-Anzahl**: für kritische Workloads in der Regel mehrere Nodes und ggf. mehrere Node Pools
- **Autoscaler**: empfohlen, häufig kombiniert mit klaren Skalierungsgrenzen pro Pool
- **Monitoring & Betrieb**: umfassendes Monitoring, Policies und Governance für geschäftskritische Umgebungen
- **Einsatz**: geeignet für Enterprise- und geschäftskritische Produktionsumgebungen mit langfristiger Planbarkeit

---

## Voraussetzungen

- Azure-Subscription mit ausreichenden Berechtigungen (`Contributor` auf der Resource Group)
- Resource Group muss vor dem Deployment existieren

---

## Deployment per Azure CLI (ARM)

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

## Deployment per Azure CLI (Bicep)

```bash
# Resource Group anlegen
az group create \
  --name rg-aks-dev \
  --location germanywestcentral

# Deployment starten
az deployment group create \
  --resource-group rg-aks-dev \
  --template-file azuredeploy.bicep \
  --parameters azuredeploy.dev.bicepparam

# kubeconfig herunterladen
az aks get-credentials \
  --resource-group rg-aks-dev \
  --name aks-dev \
  --overwrite-existing
```

---

## Optionale WebApp auf bestehendem AKS

Im Ordner `webapp` befindet sich eine einfache Q&A-WebApp, die Fragen zu AKS beantwortet und dafür einen Microsoft Learn MCP Server nutzt.

- Ziel: bestehendes AKS-Cluster weiterverwenden und nur App-Workload deployen
- Details zu Build/Run/Deploy: siehe `webapp/README.md`
- Empfohlen: Deployment über den WebApp-Button oben (einfachster Weg)

Deployment der WebApp-GitOps-Verknüpfung per CLI:

(Optional, eher für Fortgeschrittene. Für NOOBS bitte den WebApp-Button verwenden.)

```bash
az deployment group create \
  --resource-group rg-aks-dev \
  --template-file azuredeploy.webapp.bicep \
  --parameters @azuredeploy.webapp.parameters.dev.json
```

---

## Ressourcen

- [AKS Dokumentation](https://learn.microsoft.com/azure/aks/)
- [ARM Template Referenz – ManagedClusters](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters)
- [AKS Free Tier](https://learn.microsoft.com/azure/aks/free-standard-pricing-tiers)
- [AKS Premium Tier](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers#premium-tier)
