param workspaceName string

resource law 'Microsoft.OperationalInsights/workspaces@2026-03-01' existing = {
  name: workspaceName
}

resource privEscRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  scope: law
  name: guid(law.id, '1098.003')
  kind: 'Scheduled'
  properties: {
    displayName: 'Privilege Escalation - Entra Role Assignment'
    description: 'Detects privilege escalation activities'
    enabled: true
    query: loadTextContent('../detection/T1098.003_privilege_escalation_detection.kql')
    queryFrequency: 'PT15M'
    queryPeriod: 'PT30M'
    eventGroupingSettings: {
      aggregationKind: 'AlertPerResult'
    }

    severity: 'High'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionEnabled: false
    suppressionDuration: 'PT1H'
    tactics: ['Persistence', 'PrivilegeEscalation']
    techniques: ['T1098']
    entityMappings: [
      {
        entityType: 'Account'
        fieldMappings: [
          {
            identifier: 'AadUserId'
            columnName: 'TargetResourceId'
          }
        ]
      }
    ]
    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: true
        reopenClosedIncident: false
        lookbackDuration: 'PT5H'
        matchingMethod: 'AllEntities'
        groupByEntities: []
        groupByAlertDetails: []
        groupByCustomDetails: []
      }
    }
  }
}
output ruleId string = privEscRule.id
