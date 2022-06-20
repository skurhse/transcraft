@description('The location used by resources.')
param location string

@description('The base name used by resources.')
param name string

@description('The base tags used by resources.')
param tags object

@description('The bastion subnet ip prefix.')
var bastionSubnetIpPrefix = '10.1.1.0/27'

@description('The address prefixes of the network interfaces.')
var addressPrefix = '10.0.0.0/8'

@description('The address prefixes of the subnets to create.')
var subnetAddressPrefix = '10.0.0.0/16'

@description(' The tags used by resources.')
var moduleTags = union(tags, {module: 'virtualNetwork'})

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${name}VirtualNetwork'
  location: location
  tags: union(moduleTags, {resource: 'virtualNetwork'})

  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet-${uniqueString(resourceGroup().id)}'
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetIpPrefix
        }
      }
    ]
  }
}

output name string = virtualNetwork.name
