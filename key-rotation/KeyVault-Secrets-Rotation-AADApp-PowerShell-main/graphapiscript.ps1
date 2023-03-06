$TenantID = '0821259b-26fd-4642-b49a-e5a83460648f'
Connect-AzureAD -TenantId $TenantID
$functionIdentityObjectId ='4ba56305-b31e-4821-a5cb-8c95525776cd'
$graphAppId = '00000002-0000-0000-c000-000000000000' # This is a well-known Microsoft Graph application ID.
$graphApiAppRoleName = 'Application.ReadWrite.All'
$graphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$graphAppId'"
$graphApiAppRole = $graphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $graphApiAppRoleName -and $_.AllowedMemberTypes -contains "Application"}

# Assign the role to the managed identity.
New-AzureADServiceAppRoleAssignment -ObjectId $functionIdentityObjectId -PrincipalId $functionIdentityObjectId -ResourceId $graphServicePrincipal.ObjectId -Id $graphApiAppRole.Id
