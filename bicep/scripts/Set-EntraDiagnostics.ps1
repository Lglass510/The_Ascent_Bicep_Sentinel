<#
.SYNOPSIS
    Sends Entra ID AuditLogs to the Sentinel workspace so the analytics rule has data to query.
.DESCRIPTION
    Tenant-level diagnostic setting, outside the resource group scope that Bicep deploys to.
    Uses PUT, which creates or replaces the setting, so the script is safe to re-run.
#>
param(
    [string]$ResourceGroupName = "rg-ascent-ward",
    [string]$WorkspaceName     = "law-ascent-ward"
)

$ErrorActionPreference = 'Stop'

# 1. Look up the workspace's resource ID (never hardcoded)
$workspaceId = (Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.OperationalInsights/workspaces" -Name $WorkspaceName).Id

# 2. Describe the setting: AuditLogs only, sent to this workspace
$settingName = "AzureSentinel_$WorkspaceName"
$body = @{
    properties = @{
        workspaceId = $workspaceId
        logs        = @(
            @{ category = "AuditLogs"; enabled = $true }
        )
    }
} | ConvertTo-Json -Depth 5

# 3. Create or update it
$r = Invoke-AzRestMethod -Method PUT -Payload $body `
    -Path "/providers/microsoft.aadiam/diagnosticSettings/$settingName`?api-version=2017-04-01"

if ($r.StatusCode -ge 300) { throw "Failed ($($r.StatusCode)): $($r.Content)" }
Write-Output "Diagnostic setting '$settingName' -> $WorkspaceName (AuditLogs)"
