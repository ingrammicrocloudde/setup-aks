targetScope = 'resourceGroup'

@description('Name of the AKS cluster.')
@minLength(3)
@maxLength(63)
param clusterName string = 'aks-dev'

@description('Azure region for the AKS cluster.')
param location string = resourceGroup().location

@description('Number of nodes in the system node pool.')
@minValue(1)
@maxValue(5)
param nodeCount int = 1

@description('VM size for the node pool.')
@allowed([
  'Standard_B2ms'
  'Standard_B4ms'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
])
param nodeVmSize string = 'Standard_B2ms'

@description('OS disk size in GB.')
@minValue(32)
@maxValue(128)
param osDiskSizeGB int = 32

@description('Enable cluster autoscaler.')
param enableAutoScaling bool = false

@description('Minimum node count (used when autoscaling is enabled).')
@minValue(1)
@maxValue(3)
param minNodeCount int = 1

@description('Maximum node count (used when autoscaling is enabled).')
@minValue(1)
@maxValue(5)
param maxNodeCount int = 3

@description('Network plugin for the cluster.')
@allowed([
  'kubenet'
  'azure'
])
param networkPlugin string = 'kubenet'

@description('Enable Kubernetes RBAC.')
param enableRbac bool = true

@description('Enable Azure Monitor / Container Insights.')
param enableAzureMonitor bool = false

@description('Deploy the AKS Learn WebApp (Microsoft Learn MCP) into the cluster via GitOps in the same deployment.')
param deployWebApp bool = true

@description('Container image for the WebApp. Keep default to use the prebuilt public image.')
@minLength(10)
param webappImage string = 'ghcr.io/ingrammicrocloudde/aks-learn-webapp:latest'

@description('Microsoft Learn MCP Server endpoint used by the WebApp.')
param mcpServerUrl string = 'https://learn.microsoft.com/api/mcp'

@description('Internal name for the GitOps (Flux) configuration object.')
@minLength(3)
@maxLength(63)
param fluxConfigurationName string = 'aks-learn-webapp'

@description('Kubernetes namespace where the WebApp will be deployed.')
param kubernetesNamespace string = 'webapp'

@description('Git repository URL containing the Kubernetes manifests.')
param gitRepositoryUrl string = 'https://github.com/ingrammicrocloudde/setup-aks'

@description('Git branch to track.')
param gitRepositoryBranch string = 'main'

@description('Repo path with Kubernetes manifests.')
param kustomizationPath string = './webapp/k8s'

@description('Sync interval for the Git source (seconds).')
@minValue(60)
param sourceSyncIntervalSeconds int = 120

@description('Sync interval for kustomization reconciliation (seconds).')
@minValue(60)
param kustomizationSyncIntervalSeconds int = 120

@description('Tags to apply to all resources.')
param tags object = {
  Environment: 'dev'
  ManagedBy: 'ARM'
}

var nodeResourceGroup = 'MC_${resourceGroup().name}_${clusterName}_${location}'

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: clusterName
  location: location
  tags: tags
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    nodeResourceGroup: nodeResourceGroup
    enableRBAC: enableRbac
    agentPoolProfiles: [
      union({
        name: 'systempool'
        count: nodeCount
        vmSize: nodeVmSize
        osDiskSizeGB: osDiskSizeGB
        osDiskType: 'Managed'
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: enableAutoScaling
        availabilityZones: []
        nodeTaints: []
      }, enableAutoScaling ? {
        minCount: minNodeCount
        maxCount: maxNodeCount
      } : {})
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      loadBalancerSku: 'standard'
    }
    addonProfiles: {
      omsagent: {
        enabled: enableAzureMonitor
      }
    }
  }
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = if (deployWebApp) {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
  }
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = if (deployWebApp) {
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
            MCP_SERVER_URL: mcpServerUrl
          }
        }
        syncIntervalInSeconds: kustomizationSyncIntervalSeconds
        retryIntervalInSeconds: 60
        timeoutInSeconds: 120
      }
    }
    waitForReconciliation: true
  }
  dependsOn: [
    fluxExtension
  ]
}

output clusterName string = clusterName
output clusterResourceId string = aks.id
output controlPlaneFqdn string = aks.properties.fqdn
output kubeletIdentityObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
output webAppDeployed bool = deployWebApp
output fluxConfigurationResourceId string = deployWebApp ? fluxConfig.id : ''
