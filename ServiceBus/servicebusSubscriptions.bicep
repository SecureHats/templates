param serviceBusNamespaceName string

@description('Array of subscriptions and properties')
param subscriptionNames array = [
  {
    subscriptionName: 'default'
    topicName: 'default'
    lockDuration: 30
    enableSessions: false
    defaultMessageTimeToLive: 'P14DT0H0M0S'
    enableDeadLetteringOnExpiration: false
    maxDeliveryCount: 10
    deadLetteringOnFilterEvaluationExceptions: false
    duplicateDetectionWindow: 'P0DT0H0M30S'
    enableBatchedOperations: false
    autoDeleteOnIdle: 'P0DT0H0M10S'
    forwardTo: ''
  }
]

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-06-01-preview' = [for item in subscriptionNames: {
  name: '${serviceBusNamespaceName}/${item.topicName}/${item.subscriptionName}'
  properties: {
    lockDuration: 'PT${item.lockDuration}S'
    requiresSession: item.enableSessions
    defaultMessageTimeToLive: item.defaultMessageTimeToLive
    deadLetteringOnMessageExpiration: item.enableDeadLetteringOnExpiration
    maxDeliveryCount: item.maxDeliveryCount
    deadLetteringOnFilterEvaluationExceptions: item.deadLetteringOnFilterEvaluationExceptions
    duplicateDetectionHistoryTimeWindow: item.duplicateDetectionWindow
    enableBatchedOperations: item.enableBatchedOperations
    autoDeleteOnIdle: item.autoDeleteOnIdle
    forwardTo: item.forwardTo ? item.forwardTo : null 
  }
}]
