// ------
// Scopes
// ------

targetScope = 'subscription'

// -------
// Modules
// -------

module groups './modules/groups/resources.bicep' = {
  name: 'Microsoft.Resources.Groups'
  scope: subscription()
  params: {
    config: mergedConfig
  }
}

module components './modules/components/resources.bicep' = [for number in range(1,mergedConfig.numberVms): {
  name: 'Microsoft.Resources.VM${number}'
  scope: az.resourceGroup(mergedConfig.resourceGroup)
  params: {
    config: mergedConfig
    number: string(number)
    vmAdminPassword: vmAdminPassword
  }
  dependsOn: [
    groups
  ]
}]


// ---------
// Variables
// ---------

var numberOfVms = 1

var mergedConfig = union(loadJsonContent('defaults.json'), config,
{ 
  initScript: loadTextContent('scripts/post-config-win2k8r2-sql.ps1')
  location: location
  resourceGroup: resourceGroup
  numberVms: numberOfVms
  tags: tags
})


// ----------
// Parameters
// ----------

param config object = loadJsonContent('configs/main.json')

@description('adminstrator password for vms')
@secure()
param vmAdminPassword string

@description('Azure region of the deployment')
param location string = 'centralus'

@description('Name of resource group to use, created if not exists')
param resourceGroup string 


@description('Tags applied to VMs.  Must be ane object of name:value(string) pairs')
param tags object = {}

// ----------
// Outputs
// ----------

//we do not return or log the vm password since that was passed as a param
output appliedConfig object  = mergedConfig
output virtualmachines array = [for i in range(0, mergedConfig.numberVms - 1): { 
    i: components[i].outputs 
}]

