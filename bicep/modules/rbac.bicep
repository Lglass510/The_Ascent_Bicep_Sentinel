param workspaceName string
param playbookPrincipalId string
param sentinelSpObjectId string

resource law 'Microsoft.OperationalInsights/workspaces@2026-03-01' existing = {
  name: workspaceName
}

// Built-in role IDs. These are the same in every Azure tenant.
var responderRoleId = '3e150937-b8fe-4cfb-8069-0eaf05ecd056'
var automationContributorRoleId = 'f4c81013-99ee-4d62-a7ee-b3f1f648599a'

// 1. Playbook badge → Responder → on the workspace
resource playbookResponder 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: law
  name: guid(law.id, playbookPrincipalId, responderRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', responderRoleId)
    principalId: playbookPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// 2. Sentinel's badge → Automation Contributor → on the resource group
resource sentinelRunsPlaybooks 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, sentinelSpObjectId, automationContributorRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', automationContributorRoleId)
    principalId: sentinelSpObjectId
    principalType: 'ServicePrincipal'
  }
}
