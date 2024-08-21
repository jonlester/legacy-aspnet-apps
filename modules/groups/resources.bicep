// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './resources.groups.bicep' = {
  name: 'Microsoft.Resources.RGs'
  scope: subscription()
  params: {
    config: config
  }
}

module components './resources.components.bicep' = {
  name: 'Microsoft.Resources.VMs'
  scope: resourceGroup(config.resourceGroup)
  params: {
    config: config
  }
  dependsOn: [
    groups
  ]
}

// ----------
// Parameters
// ----------

param config object

