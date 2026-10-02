# Setup AKS – DEV Environment

Dieses Repository stellt ein Azure Kubernetes Service (AKS) Cluster im **DEV-Tier** bereit.  
Die Konfiguration ist auf Entwicklungsumgebungen ausgelegt: günstiger VM-Typ, einzelner Node, kostenloser AKS-SKU-Tier.

## NOOBS Quickstart (1 Schritt)

1. Klicke auf den Deploy-Button und starte das Deployment mit den Standardwerten.

Das war's: In **einem** Deployment wird sowohl das AKS-Cluster erstellt als auch die WebApp
(die den Microsoft Learn MCP Server nutzt) automatisch per GitOps in das Cluster ausgerollt.

Standardmäßig wird das vorgefertigte, öffentliche Container-Image
`ghcr.io/ingrammicrocloudde/aks-learn-webapp:latest` verwendet und der MCP-Endpoint ist auf
`https://learn.microsoft.com/api/mcp` voreingestellt – es ist keine weitere Eingabe nötig.

Optional kannst du im Portal unter den Parametern ein eigenes `webappImage` angeben oder mit
`deployWebApp = false` nur das AKS-Cluster ohne WebApp bereitstellen.

---

## Deploy to Azure

Klicke auf den Button, um AKS-Cluster **und** WebApp direkt im Azure Portal bereitzustellen:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fingrammicrocloudde%2Fsetup-aks%2Fmain%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fingrammicrocloudde%2Fsetup-aks%2Fmain%2Fazuredeploy.json)

> Hinweis: Das Deployment installiert automatisch die Flux-(GitOps-)Extension auf dem Cluster
> und wartet, bis die WebApp erfolgreich reconciled wurde. Es ist kein manuelles Anlegen eines
> Kubernetes-Secrets und kein Editieren von `webapp/k8s/deployment.yaml` erforderlich.

Die separate WebApp-Vorlage (`azuredeploy.webapp.json`) bleibt für Fortgeschrittene erhalten,
falls die WebApp auf ein bereits bestehendes AKS-Cluster ausgerollt werden soll.

---

## Architektur (Kubernetes-Überblick)

Vereinfachte Darstellung des Clusters: Eingehender Traffic erreicht über den Ingress
den Service, der die Anfragen auf die Pods des Deployments im Namespace `webapp` verteilt.

```mermaid
flowchart TB
    user([Benutzer]) --> ingress

    subgraph cluster[AKS Cluster]
        subgraph ns[Namespace: webapp]
            ingress[Ingress<br/>aks-learn-webapp]
            service[Service<br/>aks-learn-webapp :80]
            deploy[Deployment<br/>aks-learn-webapp]
            pod1[Pod<br/>webapp :3000]
            pod2[Pod<br/>webapp :3000]

            ingress --> service
            service --> pod1
            service --> pod2
            deploy -. verwaltet .-> pod1
            deploy -. verwaltet .-> pod2
        end
    end

    pod1 --> mcp([Microsoft Learn<br/>MCP Server])
    pod2 --> mcp
```

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
| `deployWebApp` | `true` | WebApp (Microsoft Learn MCP) im selben Deployment per GitOps ausrollen |
| `webappImage` | `ghcr.io/ingrammicrocloudde/aks-learn-webapp:latest` | Container-Image der WebApp |
| `mcpServerUrl` | `https://learn.microsoft.com/api/mcp` | Endpoint des Microsoft Learn MCP Servers |

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

- Standardweg: Die WebApp wird bereits vom Haupt-Deploy-Button zusammen mit dem AKS-Cluster ausgerollt (`deployWebApp = true`).
- Diese separate Vorlage ist nur nötig, wenn die WebApp auf ein **bereits bestehendes** AKS-Cluster ausgerollt werden soll.

### Ist das ein valides Szenario?

Ja. Das ist ein valides und typisches Szenario:

- Die bestehende AKS-Infrastruktur wird weiterverwendet.
- Die WebApp läuft als normaler Workload im Cluster.
- Fachwissen kommt über einen MCP Server (hier: Microsoft Learn) statt harter Wissens-Logik in der App.

### Funktionsweise (kurz)

- Browser sendet Frage an die WebApp (`POST /api/ask`).
- Die WebApp ruft ein Tool des Microsoft Learn MCP Servers auf.
- Das Tool-Ergebnis wird als Antwort zurückgegeben.

### Lokaler Start

```bash
cd webapp
npm install
set MCP_SERVER_URL=https://<dein-mcp-endpoint>
npm start
```

Dann im Browser öffnen: `http://localhost:3000`

### Container bauen

```bash
cd webapp
docker build -t aks-learn-webapp:local .
```

### Deployment per GitOps-Verknüpfung (empfohlen)

Deployment der WebApp-GitOps-Verknüpfung per CLI auf ein bestehendes Cluster. Container-Image und
MCP-Endpoint werden als Parameter übernommen und automatisch per GitOps in das Deployment
eingesetzt. Ein manuelles Anlegen eines Kubernetes-Secrets ist nicht nötig.

```bash
az deployment group create \
  --resource-group rg-aks-dev \
  --template-file azuredeploy.webapp.bicep \
  --parameters @azuredeploy.webapp.parameters.dev.json
```

### Manuelles Deployment (Fortgeschrittene)

Die Manifeste nutzen die Platzhalter `${WEBAPP_IMAGE}` und `${MCP_SERVER_URL}`, die beim
GitOps-Rollout durch Flux ersetzt werden. Bei manuellem `kubectl apply` müssen diese Platzhalter
vorher ersetzt werden.

1. Auf AKS-Kontext wechseln:

```bash
az aks get-credentials --resource-group <rg> --name <aks-name> --overwrite-existing
```

2. Container Image pushen (z. B. nach ACR oder GHCR).
3. Manifeste mit ersetzten Platzhaltern deployen:

```bash
export WEBAPP_IMAGE="ghcr.io/ingrammicrocloudde/aks-learn-webapp:latest"
export MCP_SERVER_URL="https://learn.microsoft.com/api/mcp"
envsubst < webapp/k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f webapp/k8s/service.yaml
kubectl apply -f webapp/k8s/ingress.yaml
```

4. Ingress prüfen:

```bash
kubectl get ingress aks-learn-webapp -n webapp
```

5. Falls noch nicht vorhanden: NGINX Ingress Controller im Cluster installieren.

### Wichtige Umgebungsvariablen

- `MCP_SERVER_URL` (Pflicht): URL des Microsoft Learn MCP Servers (Standard: `https://learn.microsoft.com/api/mcp`)
- `MCP_AUTH_TOKEN` (optional): Bearer Token für geschützte MCP Endpoints
- `MCP_TOOL_NAME` (optional): Expliziter Tool-Name, falls Autowahl nicht passt
- `MCP_TOOL_QUERY_PARAM` (optional, default `query`): Feldname für die Frage

### Hinweise

- Je nach MCP Server kann der Tool-Name abweichen; ggf. `MCP_TOOL_NAME` setzen.
- Für produktiven Betrieb: Ingress, TLS, WAF, Rate Limits und Observability ergänzen.
- Das Ingress-Manifest nutzt standardmäßig `ingressClassName: nginx` und den Host `aks-learn-webapp.local`.

---

## Ressourcen

- [AKS Dokumentation](https://learn.microsoft.com/azure/aks/)
- [ARM Template Referenz – ManagedClusters](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters)
- [AKS Free Tier](https://learn.microsoft.com/azure/aks/free-standard-pricing-tiers)
- [AKS Premium Tier](https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers#premium-tier)
