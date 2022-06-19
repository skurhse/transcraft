
@description('The tenant identifier used by modules.')
param tenant string = subscription().tenantId

@description('The location used by modules.')
param location string = resourceGroup().location

@description('The base name used by modules.')
param name string = 'transcraft'

@description('The deployment tags used by modules.')
param tags object = {
  deployment: name
}

@description('The service principal object id responsible for deployment.')
param servicePrincipal string

@description('The user object id used for bastion host access.')
param user string

@description('The public key data used for SSH access to the virtual machine.')
param publicKey string

@description('The private key data used for SSH access to the virtual machine.')
param privateKey string

module virtualNetwork 'modules/virtual_network.bicep' = {
  name: '${name}VirtualNetwork'
  params: {
    name: '${name}-virtual-network'
    location: location
  }
}

module bastionHost 'modules/bastion_host.bicep' = {
  name: '${name}BastionHost'
  params: {
    tenant: tenant
    location: location

    baseName: name
    baseTags: tags

    admin: servicePrincipal
    reader: user

    privateKey: privateKey

    virtualNetwork: virtualNetwork.outputs.vnetName
  }
}

module virtualMachine 'modules/virtual_machine.bicep' = {
  name: name
  params: {
    location: location
    vnetName: virtualNetwork.outputs.vnetName
    adminUsername: 'minecraft'
    computerName: name
    rsaPublicKey: publicKey
    customData: loadFileAsBase64('../out/cloud-init.mime')
  }
}

output virtualMachinePublicIpAddress string = virtualMachine.outputs.minecraftPublicIP
