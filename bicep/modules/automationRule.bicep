param workspaceName string
param analyticsRuleId string
param playbookId string

resource law 'Microsoft.OperationalInsights/workspaces@2026-03-01' existing = {
  name: workspaceName
}

resource roleEscalation 'Microsoft.SecurityInsights/automationRules@2025-09-01' = {
  scope: law
  name: guid(law.id, 'role-escalation')
  properties: {
    displayName: 'Role Escalation'
    order: 1
    triggeringLogic: {
      isEnabled: true
      triggersOn: 'Incidents'
      triggersWhen: 'Created'
      conditions: [
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentRelatedAnalyticRuleIds'
            operator: 'Contains'
            propertyValues: [
              analyticsRuleId
            ]
          }
        }
      ]
    }
    actions: [
      {
        order: 1
        actionType: 'RunPlaybook'
        actionConfiguration: {
          logicAppResourceId: playbookId
          tenantId: subscription().tenantId
        }
      }
    ]
  }
}
