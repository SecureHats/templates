param resourceName string = ''
param location string                     = resourceGroup().location
param azTags object                       = {}
param Deployment_Date string              = utcNow()
param returnStorageKey bool               = false
param allowBlobPublicAccess bool          = false
param enableAdvancedThreatProtection bool = true
param tableNames array                    = []
param containerNames array                = []

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageAccountType string = 'Standard_LRS'

@minLength(6)
@maxLength(6)
@description('Storage Account Named String. Used to auto generate SA name using combination of string and hash of resource group ID.')
param storageAccountString string = 'satemp'

var resourceName_var = empty(resourceName) ? string(toLower('uniqueString(resourceGroup().id), ${storageAccountString}')) : string(toLower(resourceName))
var objAdditionalTags = {
  displayName: 'Standard KPMG Storage Account'
  Deployment_Date: Deployment_Date
}
var extendedResourceTags = union(objAdditionalTags, azTags)

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: resourceName_var
  location: location
  tags: extendedResourceTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: allowBlobPublicAccess
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource tableservices 'Microsoft.Storage/storageAccounts/tableServices@2021-02-01' = if (!empty(tableNames)) {
  name: '${resourceName_var}/default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            '*'
          ]
          allowedMethods: [
            'PUT'
            'GET'
            'POST'
          ]
          maxAgeInSeconds: 0
          exposedHeaders: [
            '*'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      ]
    }
  }
  dependsOn: [
    storageAccount
  ]
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = if (!empty(containerNames)) {
  name: '${resourceName_var}/default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
  dependsOn: [
    storageAccount
  ]
}

resource tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2021-04-01' = [for item in tableNames: if (!empty(tableNames)) {
  name: '${resourceName_var}/default/${item}'
  dependsOn: [
    tableservices
    storageAccount
  ]
}]

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = [for item in containerNames: if (!empty(containerNames)) {
  name: '${resourceName_var}/default/${item}'
  dependsOn: [
    blob
    storageAccount
  ]
}]

resource advancedThreatProtection 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = if (enableAdvancedThreatProtection) {
  scope: storageAccount
  name: 'current'
  properties: {
    isEnabled: true
  }
}

resource lock 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: storageAccount
  name: '${resourceName} -lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'resource should not be deleted manually'
  }
}

output primaryEndpoints string  = storageAccount.properties.primaryEndpoints.blob
output storageAccountKey string = returnStorageKey ? listkeys(storageAccount.id, storageAccount.apiVersion).keys[0].value : 'null'
output managedIdentity string   = storageAccount.identity.principalId
output resourceName string      = storageAccount.name
