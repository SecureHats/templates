param serviceBusNamespaceName string

@description('Array of queues and properties')
param topicNames array = [
  {
    topicName: 'default'
    topicSize: 1024
    defaultMessageTimeToLive: 'P14DT0H0M0S'
    enableDuplicateDetection: false
    duplicateDetectionWindow: 'P0DT0H0M30S'
    enableBatchedOperations: false
    supportOrdering: false
    autoDeleteOnIdle: 'P0DT0H0M10S'
    enablePartitioning: false
    enableExpress: false
  }
]

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-06-01-preview' = [for item in topicNames: {
  name: '${serviceBusNamespaceName}/${item.topicName}'
  properties: {
    maxSizeInMegabytes: item.topicSize
    defaultMessageTimeToLive: item.defaultMessageTimeToLive
    requiresDuplicateDetection: item.enableDuplicateDetection
    duplicateDetectionHistoryTimeWindow: item.duplicateDetectionWindow
    enableBatchedOperations: item.enableBatchedOperations
    supportOrdering: item.supportOrdering
    autoDeleteOnIdle: item.autoDeleteOnIdle
    enablePartitioning: item.enablePartitioning
    enableExpress: item.enableExpress
  }
}]
