// SEE: https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.keyvault/key-vault-create-rbac <>

@description('The tenant id used by resources.')
param tenant string

@description('The location used by resources.')
param location string

@description('The deployment name used by resources.')
param baseName string

@description('The key vault tags map.')
param baseTags object 

@description('The principal object ids to be granted read access.')
param admin string
var adminRole = 'Key Vault Administrator'

@description('The principal object ids to be granted read access.')
param reader string
var readerRole = 'Key Vault Reader'

@description('The bastion private key data.')
@secure()
param bastionPrivateKeyData string

var tags = union(baseTags, {module: 'keyVault'})

var roleIdMapping = {
  'Key Vault Administrator': '00482a5a-887f-4fb3-b363-3b7fe8e74483'
  'Key Vault Reader': '21090545-7ca7-4776-b22c-e363652d74d2'
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: '${baseName}KeyVault'
  location: location
  tags: union(tags, {resource: 'keyVault'})
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: false
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    publicNetworkAccess: 'disabled'
    sku: { 
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant
  }
}

resource vaultSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '/privateKey'
  tags: tags
  properties: {
    value: bastionPrivateKeyData
  }
}

resource vaultAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleIdMapping[adminRole],admin,keyVault.id)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdMapping[adminRole])
    principalId: admin
    principalType: 'ServicePrincipal'
  }
}

resource vaultReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(roleIdMapping[readerRole],reader,keyVault.id)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleIdMapping[readerRole])
    principalId: reader
    principalType: 'User'
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'bastion-${uniqueString(resourceGroup().id)}-pip'
  location: location
  tags: {
    'app': 'minecraft'
    'resources': 'bastion-publicIp'
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: 'bastion-${uniqueString(resourceGroup().id)}-bh'
  location: location
  tags: {
    'app': 'minecraft'
    'resources': 'bastionHost'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
