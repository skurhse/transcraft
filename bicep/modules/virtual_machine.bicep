@description('The location used by resources.')
param location string

@description('The base name used by resources.')
param name string

@description('The base tags used by resources.')
param tags object

@description('The preexisting virtual network name.')
param virtualNetwork string

@description('The public key to be installed.')
param publicKey string

var vmSize = 'Standard_D2_v2'

param adminUsername string

param customData string

var moduleTags = union(tags, {module: 'virtualMachine'})

resource network 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetwork 
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${name}NetworkSecurityGroup'
  location: location
  tags: union(moduleTags, {resource: 'networkSecurityGroup'})

  properties: {
    securityRules: [
      {
        name: 'minecraft'
        properties: {
          priority: 1001
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '25565'
        }
      }
      {
        name: 'minecraft-rcon'
        properties: {
          priority: 1002
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '25575'
        }
      }
      {
        name: 'minecraft-prom'
        properties: {
          priority: 1003
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '9090'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${name}-${uniqueString(resourceGroup().id)}-pip'
  location: location
  tags: {
    'app': 'minecraft'
    'name': name
    'resources': 'publicIP'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: 'Basic'
  }
}

output minecraftPublicIP string = publicIP.properties.ipAddress


resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: '${name}-${uniqueString(resourceGroup().id)}-nic'
  location: location
  tags: {
    'app': 'minecraft'
    'name': name
    'resources': 'nic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: network.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: '${name}-${uniqueString(resourceGroup().id)}-vm'
  location: location
  tags: {
    'app': 'minecraft'
    'name': name
    'vmSize': vmSize
    'resources': 'virtualMachine'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        name: '${name}-${uniqueString(resourceGroup().id)}-disk'
        diskSizeGB: 30
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts'
        version: 'latest'
      }
    }
    priority: 'Spot'
    evictionPolicy: 'Deallocate'
    billingProfile: {
      maxPrice: -1
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      customData: customData
      linuxConfiguration: {
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: publicKey
            }
          ]
        }
      }
    }
  }
}
