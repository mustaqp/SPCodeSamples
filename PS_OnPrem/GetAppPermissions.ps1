<#
 
SYNOPSIS
This script gets the permission given to the high trust app.
 
DESCRIPTION
When troubleshooting high trust provider hosted apps. At times you may want to know what permissions the app got and to verify if the permissions mentioned in appmanifest.xml matches with that in sharepoint database

EXAMPLE
./GetAppPermissions.ps1 -SPSiteUrl "http://onpremisesiteurl" -ClientId "5260edb0-223e-408c-8ab9-e42e8da5ab8f"
 #>
 
 param(	
	[Parameter(Mandatory=$true)][string] $SPSiteUrl,
	[Parameter(Mandatory=$true)][string] $ClientId)


function getHighTrustAppPermission([string]$siteurl, [string]$appid)
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
	$web = get-spweb $siteurl
	$realm = Get-SPAuthenticationRealm -ServiceContext $web.Site
	$fullAppIdentifier = $appId + '@' + $realm
	
	cls
	
	[Microsoft.SharePoint.SPAppPrincipalPermissionsManager]$instance = new-object Microsoft.SharePoint.SPAppPrincipalPermissionsManager($web)
	$appPrincipal = Get-SPAppPrincipal -NameIdentifier $fullAppIdentifier -Site $web

	Write-Output("AppId/ClientId:"+$appId);
	Write-Output("App DisplayName:"+$appPrincipal.DisplayName);
	Write-Output("App Identifier :"+$appPrincipal.EncodedNameIdentifier);
	Write-Output("");
	Write-Output("Permissions are");

	Write-Output("Web: "+$instance.GetAppPrincipalWebPermission($appPrincipal));
	Write-Output("Site: "+$instance.GetAppPrincipalSitePermission($appPrincipal));
	Write-Output("Tenant: "+$instance.GetAppPrincipalSiteSubscriptionContentPermission($appPrincipal));

	$permScopeGuids = @{
		#"BDC" = "387db76f-037d-489b-b8f7-905ccf8adb9c";
		"Taxonomy" = "0d4a59a6-7cbc-4be5-8241-4d40fd280158";
		"Search" = "e35199bf-3211-4334-a279-a8752d370e55";
		"Social" = "a2ccc2e2-1703-4bd9-955f-77b2550d6f0d";
		"Social Trimming" = "17a6290f-30a3-49fd-8b2b-5f4da225c424";
		"User Profiles (Social)" = "fcaec196-a98c-4f8f-b60f-e1a82272a6d2";
		#"Project" = "99dce5f7-7743-4b6d-89d4-5bfbbbc2ef63";
	} 

	$permScopeGuids.Keys | ForEach-Object{
		$scopeName = $_
		$scopeGuid = [GUID]$permScopeGuids[$_]        
		$permByteArray = $instance.GetAppPrincipalSiteSubscriptionPermission($appPrincipal, $scopeGuid);
		if(-not([string]::IsNullOrEmpty($permByteArray)))
		{
			$permBitwise = [System.BitConverter]::ToInt32($permByteArray, 0);
			$permValue = [Microsoft.SharePoint.SPAppPrincipalPermissionKind]$permBitwise;
			Write-Output($scopeName+ ": " +$permValue);
		}
		else
		{
			Write-Output($scopeName+ ": Not Found");        
		}
	}
	##works but returns 48.0 (which is Read right) instead of bitwise returned by other permission and cannot find PermissionKind enum for that.	
	##ScopeUri=http://sharepoint/bcs/connection
	#$bcsPermGuid = [GUID]("387db76f-037d-489b-b8f7-905ccf8adb9c")
	#$permBytes = $instance.GetAppPrincipalSiteSubscriptionPermission($appPrincipal, $bcsPermGuid);
	#$permBitwise = [System.BitConverter]::ToInt32($permBytes, 0);
	#$permValue = [Microsoft.SharePoint.SPAppPrincipalPermissionKind]$permBitwise;
	#Write-Output("http://sharepoint/bcs/connection: "+$permValue); 

}

$ErrorActionPreference = "Stop"
getHighTrustAppPermission $SPSiteUrl $ClientId
