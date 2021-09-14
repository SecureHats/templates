param resourceName string = ''
param location string = resourceGroup().location
param virtualNetworkResourceGroup string = ''
param virtualNetworkName string = ''
param subnetName string = ''
param zoneRedundant bool = true
param storageAccountName string = ''
param workspaceResourceId string = ''
param azTags object = {}
param keyVaultName string = ''
param keyName string = ''
param customerManagedKey bool = false

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Premium'
@allowed([
  1
  2
  4
])
param skuCapacity int = 1

@minValue(0)
@maxValue(365)
param logRetentionInDays int = 14

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
  scope: resourceGroup('${virtualNetworkResourceGroup}')
}

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource sb 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: resourceName
  location: location
  tags: azTags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    zoneRedundant: zoneRedundant
    encryption: customerManagedKey ? {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: [
        {
          keyName: keyName
          keyVaultUri: kv.properties.vaultUri
        }
      ]
    } : null
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource sbNetworkRuleSet 'Microsoft.ServiceBus/namespaces/networkRuleSets@2021-01-01-preview' = if (skuName != 'Basic' ) {
  name: concat('${sb.name}/default')
  properties: {
    defaultAction: 'Deny'
    virtualNetworkRules: [
      {
        subnet: {
          id: subnet.id
        }
        ignoreMissingVnetServiceEndpoint: true
      }
    ]
    ipRules: []
  }
}

resource analytics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(workspaceResourceId)) {
  scope: sb
  name: 'service'
  properties: {
    workspaceId: workspaceResourceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource logs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(storageAccountName)) {
  scope: sb
  name: 'storageaccount-log'
  properties: {
    storageAccountId: stg.id
    logs: [
      {
        enabled: true
        category: 'OperationalLogs'
        retentionPolicy: {
          enabled: !(logRetentionInDays == 0)
          days: logRetentionInDays
        }
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
        retentionPolicy: {
          enabled: !(logRetentionInDays == 0)
          days: logRetentionInDays
        }
      }
    ]
  }
}

resource lock 'Microsoft.Authorization/locks@2016-09-01' = {
  scope: sb
  name: concat('${resourceName} -lock')
  properties: {
    level: 'CanNotDelete'
    notes: 'resource should not be deleted manually'
  }
}
