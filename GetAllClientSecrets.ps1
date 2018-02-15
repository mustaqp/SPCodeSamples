# Need Azure Active Directory Powershell Module
#https://support.office.com/en-us/article/Connect-PowerShell-to-Office-365-services-06a743bb-ceb6-49a9-a61d-db4ffdf54fa6

#Also Need Online Sign in assistant
#https://www.microsoft.com/en-us/download/details.aspx?id=39267


Import-module MSOnline -ErrorAction Continue
$msolcred = get-credential
connect-msolservice -credential $msolcred

# List secrets that are expired or about to expire within 10 days from Today.
$dayLimit = 10;
$currentDate = (Get-Date).ToShortDateString();

$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

$allExpiredKeys = @()
$allValidKeys = @()


$applist = Get-MsolServicePrincipal -all  | Where-Object -FilterScript { ($_.DisplayName -notlike "*Microsoft*") -and ($_.DisplayName -notlike "autohost*") -and  ($_.ServicePrincipalNames -notlike "*localhost*")}

foreach ($appentry in $applist)
{
    $principalId = $appentry.AppPrincipalId.Guid
    $principalName = $appentry.DisplayName
    
    $clientSecrets = Get-MsolServicePrincipalCredential -AppPrincipalId $principalId -ReturnKeyValues $false | Where-Object { ($_.Type -ne "Other") -and ($_.Type -ne "Asymmetric") }
    
    if ($clientSecrets -ne $null)
    {
        foreach ($secret in $clientSecrets)
        {
            $clientSecret = "" | Select "PrincipalName","PrincipalID","KeyId","SecretType","StartDate","EndDate","Usage"
            $clientSecret.PrincipalName = $principalName
            $clientSecret.PrincipalID = $principalId
            $clientSecret.KeyId = $secret.KeyId
            $clientSecret.SecretType = $secret.Type
            $clientSecret.StartDate = $secret.StartDate
            $clientSecret.EndDate = $secret.EndDate
            $clientSecret.Usage = $secret.Usage
            $keyEndDate = $secret.EndDate.ToShortDateString();
            $dayDiff = New-TimeSpan -Start $currentDate -End $keyEndDate

            if($dayDiff.Days -le $dayLimit)
            {
                $allExpiredKeys += $clientSecret
            }
            else
            {
                $allValidKeys += $clientSecret
            }

        }
    }


} 

$allValidKeys | Out-File "$ScriptDir\Secret_Valid.txt"
$allExpiredKeys | Out-File "$ScriptDir\Secret_Expiring.txt"

Write-Host "Done."