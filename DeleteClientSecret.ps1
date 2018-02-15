# Need Azure Active Directory Powershell Module
#https://support.office.com/en-us/article/Connect-PowerShell-to-Office-365-services-06a743bb-ceb6-49a9-a61d-db4ffdf54fa6

#Also Need Online Sign in assistant
#https://www.microsoft.com/en-us/download/details.aspx?id=39267


Import-module MSOnline -ErrorAction Continue
$msolcred = get-credential
connect-msolservice -credential $msolcred

$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

function DeleteExpiredKeys($appClientId) 
{
    $allExpiredKeys = @()
    $keysToDelete = @()
    $applist = Get-MsolServicePrincipal -all  | Where-Object -FilterScript { ($_.AppPrincipalId.Guid -eq $appClientId)}
    foreach ($appentry in $applist)
    {
        $principalId = $appentry.AppPrincipalId.Guid
        $principalName = $appentry.DisplayName    
        $clientSecrets = Get-MsolServicePrincipalCredential -AppPrincipalId $principalId -ReturnKeyValues $false | Where-Object { ($_.Type -ne "Other") -and ($_.Type -ne "Asymmetric") }
    
        if ($clientSecrets -ne $null)
        {
            foreach ($secret in $clientSecrets)
            {
                $keysToDelete += $secret.KeyId                
                $clientSecret = "" | Select "PrincipalName","PrincipalID","KeyId","SecretType","StartDate","EndDate","Usage"
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

    $allExpiredKeys | Out-File "$ScriptDir\Secret_Deleted.txt"
    Write-Host "Done."
} 

$appClientId = '041bf128-4442-45aa-bb37-d57167sa080b'
DeleteExpiredKeys($appClientId)
Write-Host "Successfully Deleted Keys for ClientId $appClientId" 