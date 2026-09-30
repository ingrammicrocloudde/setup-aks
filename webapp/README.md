# Webapp: AKS Learn Assistant (MCP)

Dieses Verzeichnis enthält eine einfache WebApp, die Fragen zu AKS beantwortet und dazu einen Microsoft Learn MCP Server abfragt.

## Ist das ein valides Szenario?

Ja. Das ist ein valides und typisches Szenario:

- Die bestehende AKS-Infrastruktur wird weiterverwendet.
- Die WebApp läuft als normaler Workload im Cluster.
- Fachwissen kommt über einen MCP Server (hier: Microsoft Learn) statt harter Wissens-Logik in der App.

## Architektur (kurz)

- Browser sendet Frage an die WebApp (`POST /api/ask`).
- Die WebApp ruft ein Tool des Microsoft Learn MCP Servers auf.
- Das Tool-Ergebnis wird als Antwort zurückgegeben.

## Lokaler Start

```bash
cd webapp
npm install
set MCP_SERVER_URL=https://<dein-mcp-endpoint>
npm start
```

Dann im Browser öffnen: `http://localhost:3000`

## Container bauen

```bash
cd webapp
docker build -t aks-learn-webapp:local .
```

## Deployment in ein vorhandenes AKS Cluster

Empfehlung (NOOBS-freundlich): Deployment über den Deploy-to-Azure-Button im Root-README. Dabei wird das Container-Image als Parameter abgefragt und automatisch in das Deployment übernommen.

1. Auf AKS-Kontext wechseln:

```bash
az aks get-credentials --resource-group <rg> --name <aks-name> --overwrite-existing
```

2. Container Image pushen (z. B. nach ACR oder GHCR).
3. Secret mit MCP Konfiguration anlegen:

```bash
kubectl create secret generic aks-learn-webapp-secrets \
  --from-literal=MCP_SERVER_URL="https://<dein-mcp-endpoint>" \
  --from-literal=MCP_AUTH_TOKEN="<optional-token>"
```

4. Manifeste deployen:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

5. Ingress prüfen:

```bash
kubectl get ingress aks-learn-webapp
```

6. Falls noch nicht vorhanden: NGINX Ingress Controller im Cluster installieren.

## Wichtige Umgebungsvariablen

- `MCP_SERVER_URL` (Pflicht): URL des Microsoft Learn MCP Servers
- `MCP_AUTH_TOKEN` (optional): Bearer Token für geschützte MCP Endpoints
- `MCP_TOOL_NAME` (optional): Expliziter Tool-Name, falls Autowahl nicht passt
- `MCP_TOOL_QUERY_PARAM` (optional, default `query`): Feldname für die Frage

## Hinweise

- Je nach MCP Server kann der Tool-Name abweichen; ggf. `MCP_TOOL_NAME` setzen.
- Für produktiven Betrieb: Ingress, TLS, WAF, Rate Limits und Observability ergänzen.
- Das Ingress-Manifest nutzt standardmäßig `ingressClassName: nginx` und den Host `aks-learn-webapp.local`.
