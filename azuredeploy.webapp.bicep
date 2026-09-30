targetScope = 'resourceGroup'

@description('Existing AKS cluster name from the first deployment button (example: aks-dev).')
param aksClusterName string

@description('Internal name for GitOps link object. Keep default unless you need multiple web app configs.')
@minLength(3)
@maxLength(63)
param fluxConfigurationName string = 'aks-learn-webapp'

@description('Kubernetes namespace where the web app will be deployed (example: webapp).')
param kubernetesNamespace string = 'webapp'

@description('Git repository URL containing the Kubernetes manifests. Normally keep default for this repo.')
param gitRepositoryUrl string = 'https://github.com/ingrammicrocloudde/setup-aks'

@description('Git branch to track (example: main).')
param gitRepositoryBranch string = 'main'

@description('Repo path with Kubernetes manifests (example: ./webapp/k8s).')
param kustomizationPath string = './webapp/k8s'

@description('Required container image for deployment. Examples: myacr.azurecr.io/aks-learn-webapp:v1 or ghcr.io/my-org/aks-learn-webapp:latest')
@minLength(10)
param webappImage string

@description('Sync interval for the Git source (seconds).')
@minValue(60)
param sourceSyncIntervalSeconds int = 120

@description('Sync interval for kustomization reconciliation (seconds).')
@minValue(60)
param kustomizationSyncIntervalSeconds int = 120

@description('Maximum time to wait for Flux reconciliation (ISO 8601 duration, for example PT30M).')
param reconciliationWaitDuration string = 'PT30M'

resource aks 'Microsoft.ContainerService/managedClusters@2024-05-01' existing = {
  name: aksClusterName
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
  name: fluxConfigurationName
  scope: aks
  properties: {
    scope: 'cluster'
    namespace: kubernetesNamespace
    sourceKind: 'GitRepository'
    gitRepository: {
      url: gitRepositoryUrl
      repositoryRef: {
        branch: gitRepositoryBranch
      }
      syncIntervalInSeconds: sourceSyncIntervalSeconds
      timeoutInSeconds: 60
    }
    kustomizations: {
      webapp: {
        path: kustomizationPath
        prune: true
        force: false
        postBuild: {
          substitute: {
            WEBAPP_IMAGE: webappImage
          }
        }
        syncIntervalInSeconds: kustomizationSyncIntervalSeconds
        retryIntervalInSeconds: 60
        timeoutInSeconds: 120
      }
    }
    waitForReconciliation: true
    reconciliationWaitDuration: reconciliationWaitDuration
  }
}

output fluxConfigurationResourceId string = fluxConfig.id
output nextStep string = 'Create secret aks-learn-webapp-secrets with MCP_SERVER_URL, then wait for GitOps reconciliation to complete.'
