param lawName string 
param location string = resourceGroup().location
param sentinelSpObjectId string
resource law 'Microsoft.OperationalInsights/workspaces@2026-03-01' = { 
name: lawName
location:location
properties: { 
  sku: {
    name: 'PerGB2018'
  }
  retentionInDays: 90
}

}

resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2025-09-01'= {
  scope: law
  name: 'default'
  properties: {
  }
}

resource watchlist 'Microsoft.SecurityInsights/watchlists@2025-09-01' = { 
  scope: law
  name: 'AutomationExclusions'
   dependsOn: [
      sentinel
    ]
  properties: { 
   
    displayName: 'AutomationExclusions'
    provider: 'Custom'
    source: 'AutomationExclusions.csv'
    sourceType: 'Local'
    itemsSearchKey: 'UserObjectId'
    numberOfLinesToSkip: 0
    contentType: 'text/csv'
    rawContent: loadTextContent('data/AutomationExclusions.csv')

  }
}

module privEscRule './modules/analyticsRule.bicep' = {
  name: 'privEscRule'
  params: {
    workspaceName: lawName
  }
  dependsOn: [
    sentinel
  ]
}
module playbook 'modules/playbook.bicep' = {
  name: 'playbook'
  params: {
    workspaceName: law.name
    location: location
  }
  dependsOn: [
    sentinel
  ]
}
module rbac 'modules/rbac.bicep' = {
  name: 'rbac'
  params: {
    workspaceName: law.name
    playbookPrincipalId: playbook.outputs.principalId
    sentinelSpObjectId: sentinelSpObjectId
  }
}
module automationRule 'modules/automationRule.bicep' = {
  name: 'automationRule'
  params: {
    workspaceName: law.name
    analyticsRuleId: privEscRule.outputs.ruleId
    playbookId: playbook.outputs.playbookId
  }
  dependsOn: [
    rbac
  ]
}
