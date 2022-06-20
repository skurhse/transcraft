@description('The location used by resources.')
param location string

@description('The base name used by resources.')
param name string

@description('The base tags used by resources.')
param tags object

@description('The address prefixes of the network interfaces.')
var addressPrefix = '10.0.0.0/8'

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
  }
}

output name string = virtualNetwork.name
