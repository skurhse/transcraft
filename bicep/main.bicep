param sshPrivateKey string
param sshPublicKey string

param spObjectId string
param userObjectId string

param location string = resourceGroup().location

module minecraftVault 'modules/keyvault.bicep' = {
  name: 'minecraft-vault'
  params: {
    spObjectId: spObjectId
    userObjectId: userObjectId
    sshPrivateKey: sshPrivateKey
    location: location
  }
}

module minecraftVnet 'modules/network.bicep' = {
  name: 'minecraft-vnet'
  params: {
    location: location
  }
}

module minecraftBastion 'modules/bastion.bicep' = {
  name: 'minecraft-bastion'
  params: {
    location: location
    vnetName: minecraftVnet.outputs.vnetName
  }
}

var minecraftServeNames = [
  'minecraft-server-1'
]

module minecraftServer 'modules/minecraft.bicep' = [for name in minecraftServeNames: {
  name: name
  params: {
    location: location
    vnetName: minecraftVnet.outputs.vnetName
    adminUsername: 'minecraft'
    computerName: name
    sshPublicKey: sshPublicKey
    customData: loadFileAsBase64('../cloud-init/cloud-config.yaml')
  }
}]

output minecraftPublicIP array = [for (item, index) in minecraftServeNames: {
  name: item
  value: minecraftServer[index].outputs.minecraftPublicIP
}]
