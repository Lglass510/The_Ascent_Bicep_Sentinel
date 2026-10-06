param workspaceName string
param location string
param playbookName string = 'Block-Entra-ID-user---Incident'


resource law 'Microsoft.OperationalInsights/workspaces@2026-03-01' existing = {
  name: workspaceName
}
var sentinelApiId = subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuresentinel')

resource sentinelConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'microsoftsentinel-${playbookName}'
  location: location
  kind: 'V1'
  properties: {
    displayName: 'microsoftsentinel-${playbookName}'
    parameterValueType: 'Alternative'
    api: {
      id: sentinelApiId
    }
  }
}

resource playbook 'Microsoft.Logic/workflows@2019-05-01' = {
  name: playbookName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('../playbook/workflow.json' )
    parameters: {
      '$connections': {
        value: {
          microsoftsentinel: {
            connectionId: sentinelConnection.id
            connectionName: sentinelConnection.name 
            id: sentinelApiId
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
        }
      }
workspaceId: {
  value: law.id
}


    }
  }
}
output principalId string = playbook.identity.principalId
output playbookId string = playbook.id
