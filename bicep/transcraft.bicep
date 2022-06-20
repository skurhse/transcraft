@description('The service principal object id responsible for deployment.')
param servicePrincipal string

@description('The user object id used for bastion host access.')
param user string

@description('The public key data used for SSH access to the virtual machine.')
param publicKey string

@description('The private key data used for SSH access to the virtual machine.')
@secure()
param privateKey string

@description('The location used by modules.')
param location string = resourceGroup().location

@description('The tenant identifier used by modules.')
var tenant = subscription().tenantId

@description('The base name used by modules.')
var name = 'transcraft'

@description('The deployment tags used by modules.')
var tags = {
  deployment: name
}

module virtualNetwork 'modules/virtual_network.bicep' = {
  name: '${name}VirtualNetwork'
  params: {
    location: location

    name: name
    tags: tags
  }
}

module bastionHost 'modules/bastion_host.bicep' = {
  name: '${name}BastionHost'
  params: {
    tenant: tenant
    location: location

    name: name
    tags: tags

    virtualNetwork: virtualNetwork.outputs.name

    admin: servicePrincipal
    reader: user
    privateKey: privateKey
  }
}

module virtualMachine 'modules/virtual_machine.bicep' = {
  name: '${name}VirtualMachine'
  params: {
    location: location

    name: name
    tags: tags

    virtualNetwork: virtualNetwork.outputs.name

    adminUsername: 'minecraft'
    publicKey: publicKey
    customData: loadFileAsBase64('../out/cloud-init.mime')
  }
}

output virtualMachinePublicIpAddress string = virtualMachine.outputs.minecraftPublicIP
