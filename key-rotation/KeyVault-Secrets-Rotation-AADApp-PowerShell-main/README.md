# KeyVault-Secrets-Rotation-AADApp-PowerShell

Functions regenerate individual key (alternating between two keys) in AAD App client secret and add regenerated client secret to Key Vault as new version of the same secret.

## Features

* Rotation function for AAD App client secret triggered by Event Grid (AKVAADAppClientSecretRotation)

* Rotation function for AAD App client secret key triggered by HTTP call (AKVAADAppClientSecretRotationHttp)

* ARM template for function deployment with secret deployment (optional)

* ARM template for adding AAD App client secret to existing function with secret deployment (optional)

## Steps
Please update the deploy parameters file with the client secret you would like to manage and deploy the azuredeploy.json file referencing the deploymentPaarmeters.josn

## Overview

Functions using following information stored in secret as tags:

* $secret.Tags["ValidityPeriodDays"] - number of days, it defines expiration date for new secret
* $secret.Tags["CredentialId"] - AAD App Client Secret credential id
* $secret.Tags["ProviderAddress"] - AAD App App Object Id

You can deploy vault secret with above tags and AAD App client secret as value or add those tags to existing secret with Indentity Platform client secret value. For automated rotation expiry date will also be required - key vault triggers 'SecretNearExpiry' event 30 days before expiry.
[ServiceType]
There are two available functions performing same rotation:

* AKVAADAppClientSecretRotation - event triggered function, performs AAD App client secret rotation triggered by Key Vault events. In this setup Near Expiry event is used which is published 30 days before expiration
* AKVAADAppClientSecretRotationHttp - on-demand function with KeyVaultName and Secret name as parameters

Functions are using Function App identity to access Key Vault and existing secret "CredentialId" tag with AAD App client secret name and "ProviderAddress" with AAD App app Resource Id.

### Installation

1. Install function with template for AAD App client secret
1. Add permissions using Graph API to Azure Function to generate client secrets in AAD App

ARM templates available:

* [Secrets rotation Azure Function and configuration deployment template](https://github.com/Azure/KeyVault-Secrets-Rotation-AADApp-PowerShell/blob/main/ARM-Templates/Readme.md) - it creates and deploys function app and function code, creates necessary permissions, Key Vault event subscription for Near Expiry Event for individual secret (secret name can be provided as parameter)
* [Add event subscription to existing Azure Function deployment template](https://github.com/Azure/KeyVault-Secrets-Rotation-AADApp-PowerShell/blob/main/ARM-Templates/Readme.md) - function can be used for multiple services for rotation. This template creates new event subscription for secret and necessary permissions to existing function

Steps to add Graph API permissions to Azure Function:

> [!IMPORTANT]
> To provide Graph API Permission you need to be Global Administrator in Azure Active Directory

```powershell
$TenantID = '<Directory Tenant Id>'
Connect-AzureAD -TenantId $TenantID
$functionIdentityObjectId ='<Azure Function Identity Object Id>'
$graphAppId = '00000003-0000-0000-c000-000000000000' # This is a well-known Microsoft Graph application ID.
$graphApiAppRoleName = 'Application.ReadWrite.All'
$graphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$graphAppId'"
$graphApiAppRole = $graphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $graphApiAppRoleName -and $_.AllowedMemberTypes -contains "Application"}

# Assign the role to the managed identity.
New-AzureADServiceAppRoleAssignment -ObjectId $functionIdentityObjectId -PrincipalId $functionIdentityObjectId -ResourceId $graphServicePrincipal.ObjectId -Id $graphApiAppRole.Id

```

* Please also run the above powershell script changing the graphAppId to = 00000002-0000-0000-c000-000000000000
* Provide Azure AD role to the function object ID - KeyVault Secret Officer


* --TODO--
- Use of Secret String in conjunction with the KV, however this could be avoided with implimenting the secrets with the parameter file and raising a http manual event trigaring the eventgid and functions to genarate a new version of the secrets in the KV. 

- Needs to align with the dev team so that the secrets are used inconjunction with dynamic KV target string so that a new version of secret does not break the trust chain.
