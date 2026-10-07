using './main.bicep'

param lawName = 'law-ascent-ward2'

// Object ID of Sentinel's own service principal ("Azure Security Insights"). It differs per tenant.
// Look yours up with: (Get-AzADServicePrincipal -DisplayName "Azure Security Insights").Id
param sentinelSpObjectId = '<azure-security-insights-object-id>'
