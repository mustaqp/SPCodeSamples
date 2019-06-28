<# 
Code Example Disclaimer:
Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. 
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED 'AS IS'-This is intended as a sample of how code might be written 
for a similar purpose and you will need to make changes to fit to your requirements. 
-This code has not been tested. This code is also not to be considered best practices or prescriptive guidance.
-No debugging or error handling has been implemented.
-It is highly recommended that you FULLY understand what this code is doing  and use this code at your own risk.

Need Azure Active Directory Powershell Module
https://support.office.com/en-us/article/Connect-PowerShell-to-Office-365-services-06a743bb-ceb6-49a9-a61d-db4ffdf54fa6
Also Need Online Sign in assistant
https://www.microsoft.com/en-us/download/details.aspx?id=39267

Use Case: Low Trust Provider Hosted Apps or Add-ins require Client Secret, which are valid for either 1 or 3 years. Once they Expire, 
the apps will stop working and you need to generate new once for that particular appId or clientId. Before generating new secret, 
it is recommended to delete the old secret for that particular clientid or appid. 
This PowerShell Script connects to Azure Active Directory and will delete all expired and unexpired client secret for the given clientid. 
Note that a client secret contains 3 keys and all 3 keys needs to be deleted. This script will take care of that. 
Once done you can run CreateClientSecret.ps1  

Usage:
Open the file and update the value of $appOrClientId with your clientId or AppId for which you want to delete the Secret. 
Save the ps1. Open Windows Powershell in administrative mode and cd to the location where you save this script.
Run the script. It will prompt for your onmicrosoft account and password. Once authentication succeeds 
before deleting the keys, script logs it in Secret_Deleted.txt at C:\Temp Folder.
#> 

#Requires -Modules MSOnline

$msolcred = get-credential
connect-msolservice -credential $msolcred

Function DeleteKeys
{
    Param(
        [string]
        [Parameter(Mandatory=$true)]
        [Alias("ClientId")]
        $AppId,

        [string]
        [Parameter(Mandatory=$false)]        
        $PathToSaveOutput = "C:\Temp"
    )
    $allExpiredKeys = @()
    $keysToDelete = @()
    $applist = Get-MsolServicePrincipal -all  | Where-Object -FilterScript { ($_.AppPrincipalId.Guid -eq $AppId)}
    foreach ($appentry in $applist)
    {
        $principalId = $appentry.AppPrincipalId.Guid
        $principalName = $appentry.DisplayName    
        $clientSecrets = Get-MsolServicePrincipalCredential -AppPrincipalId $principalId -ReturnKeyValues $false | Where-Object { ($_.Type -ne "Other") -and ($_.Type -ne "Asymmetric") }
    
        if ($null -ne $clientSecrets)
        {
            foreach ($secret in $clientSecrets)
            {
                $keysToDelete += $secret.KeyId                
                $clientSecret = "" | Select-Object "PrincipalName","PrincipalID","KeyId","SecretType","StartDate","EndDate","Usage"
                $clientSecret.PrincipalName = $principalName
                $clientSecret.PrincipalID = $principalId
                $clientSecret.KeyId = $secret.KeyId
                $clientSecret.SecretType = $secret.Type
                $clientSecret.StartDate = $secret.StartDate
                $clientSecret.EndDate = $secret.EndDate
                $clientSecret.Usage = $secret.Usage
                $allExpiredKeys += $clientSecret
            } 
                        
            Remove-MsolServicePrincipalCredential -KeyIds @($keysToDelete) -AppPrincipalId $principalId                                      
        }
    }

    $allExpiredKeys | Out-File "$PathToSaveOutput\Secret_Deleted.txt"
    Write-Host "Done. OutPut Saved at $PathToSaveOutput"
} 

#replace with your appid or clientId
$appOrClientId = 'a9554ccc-14ed-48e8-a58f-f57a96d44f90'
DeleteKeys -AppId $appOrClientId

#path of directory to save the output. if not supplied default is C:\Temp\ 
#DeleteKeys -AppId $appOrClientId -PathToSaveOutput "C:\mysamples\AADSecrets"

Write-Host "Successfully Deleted Keys for ClientId $appOrClientId" 
