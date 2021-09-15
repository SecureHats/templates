param resourcename string = ''
param location string = resourceGroup().location
param resourceid string = ''
param subnetResourceId string = ''
param groupId string = ''

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: resourcename
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: resourcename
        properties: {
          privateLinkServiceId: resourceid
          groupIds: [
            groupId
          ]
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnetResourceId
      name: resourcename
      properties: {
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }
  }
}
