param serviceBusNamespaceName string

@description('Array of queues and properties')
param queueNames array = [
  {
    queueName: 'default'
    queueSize: 1024
    defaultMessageTimeToLive: 'P14DT0H0M0S'
    lockDuration: 30
    enableDuplicateDetection: false
    duplicateDetectionWindow: 'P0DT0H0M30S'
    enableDeadLetteringOnExpiration: false
    enableSessions: false
    maxDeliveryCount: 10
    enablePartitioning: false
    enableExpress: false
  }
]

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2017-04-01' = [for item in queueNames: {
  name: '${serviceBusNamespaceName}/${item.queueName}'
  properties: {
    lockDuration: 'PT${item.lockDuration}S'
    maxSizeInMegabytes: item.queueSize
    requiresDuplicateDetection: item.enableDuplicateDetection
    duplicateDetectionHistoryTimeWindow: item.duplicateDetectionWindow
    requiresSession: item.enableSessions
    defaultMessageTimeToLive: item.defaultMessageTimeToLive
    deadLetteringOnMessageExpiration: item.enableDeadLetteringOnExpiration
    maxDeliveryCount: item.maxDeliveryCount
    enablePartitioning: item.enablePartitioning
    enableExpress: item.enableExpress
  }
}]
