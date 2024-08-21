// ------
// Scopes
// ------

targetScope = 'resourceGroup'

// ---------
// Resources
// ---------


resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${config.vm.publicIpName}${number}'
  location: config.location
  sku: {
    name: config.vm.publicIpSku
  }
  properties: {
    publicIPAllocationMethod: config.vm.publicIPAllocationMethod
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${config.vm.nicName}${number}'
  location: config.location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', config.resources.virtualNetworkName, config.vnet.subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${config.resources.vmName}${number}'
  location: config.location
  tags: config.tags
  properties: {
    hardwareProfile: {
      vmSize: config.vm.vmSize
    }
    osProfile: {
      computerName: '${config.resources.vmName}${number}'
      adminUsername: config.vm.adminUsername
      adminPassword: vmAdminPassword
      customData: base64(config.initScript)
    }
    storageProfile: {
      imageReference: config.imageReference
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}


resource vmRunCommand 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: 'vmRunCommand${number}'
  location: config.location
  parent: vm
  properties: {
    asyncExecution: false
    source: {
      script: config.runCommand
    }
  }
}

// ----------
// Parameters
// ----------

param config object
param number string
@secure()
param vmAdminPassword string

// output
output vmCreated object = {
  name: vm.name
  runCommandId: vmRunCommand.id
}

