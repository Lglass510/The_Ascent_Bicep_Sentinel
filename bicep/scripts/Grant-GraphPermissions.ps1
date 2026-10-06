<#
.SYNOPSIS
    Grants the playbook's managed identity the Microsoft Graph app roles it needs to disable users.

.DESCRIPTION
    Post-deployment step for The Ascent. Graph app roles live in Entra ID, outside the resource
    group that main.bicep deploys into, so they are granted here instead of in Bicep.

    Idempotent: roles the identity already holds are skipped, so the script is safe to re-run.
#>
param(
    [string]$ResourceGroupName = "rg-ascent-ward",
    [string]$PlaybookName      = "Block-Entra-ID-user---Incident"
)

# Stop at the first error instead of carrying on with missing values.
$ErrorActionPreference = 'Stop'

# 1. Look up the playbook's managed identity. Never hardcoded: it changes when the playbook is rebuilt.
$miId = (Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Logic/workflows" -Name $PlaybookName).Identity.PrincipalId
if (-not $miId) { throw "No managed identity found for '$PlaybookName' in '$ResourceGroupName'." }

# 2. Connect to Graph in the same tenant as the current Azure session (avoids signing in to a personal MSA).
$tenantId = (Get-AzContext).Tenant.Id
Connect-MgGraph -TenantId $tenantId -Scopes "Application.Read.All","AppRoleAssignment.ReadWrite.All" -NoWelcome

# 3. Find Microsoft Graph's service principal and the two app roles (least privilege for disabling users).
$graph = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$roles = $graph.AppRoles | Where-Object {
    $_.Value -in "User.EnableDisableAccount.All","User.Read.All" -and
    $_.AllowedMemberTypes -contains "Application"
}

# 4. App roles the identity already holds.
$existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miId

# 5. Grant only what's missing.
foreach ($role in $roles) {
    if ($existing.AppRoleId -contains $role.Id) {
        Write-Output "Already assigned: $($role.Value)"
    }
    else {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $miId `
            -PrincipalId $miId -ResourceId $graph.Id -AppRoleId $role.Id | Out-Null
        Write-Output "Granted: $($role.Value)"
    }
}
