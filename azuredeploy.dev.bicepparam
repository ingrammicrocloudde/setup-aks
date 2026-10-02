using './azuredeploy.bicep'

param clusterName = 'aks-dev'
param nodeCount = 1
param nodeVmSize = 'Standard_B2ms'
param osDiskSizeGB = 32
param enableAutoScaling = false
param networkPlugin = 'kubenet'
param enableRbac = true
param enableAzureMonitor = false
param deployWebApp = true
param webappImage = 'ghcr.io/ingrammicrocloudde/aks-learn-webapp:latest'
param mcpServerUrl = 'https://learn.microsoft.com/api/mcp'
param tags = {
  Environment: 'dev'
  ManagedBy: 'ARM'
  CostCenter: 'dev-team'
}
