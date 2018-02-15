# Need Azure Active Directory Powershell Module
#https://support.office.com/en-us/article/Connect-PowerShell-to-Office-365-services-06a743bb-ceb6-49a9-a61d-db4ffdf54fa6

#Also Need Online Sign in assistant
#https://www.microsoft.com/en-us/download/details.aspx?id=39267


Import-module MSOnline -ErrorAction Continue
$msolcred = get-credential
connect-msolservice -credential $msolcred


$secretValidity = 3
$secretStartDate = [System.DateTime]::Now


$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

function CreateNewClientSecret($appClientId) 
{   
    $newkey = "" | Select "ClientId","ClientSecret" 
    $bytes = New-Object Byte[] 32
    $rand = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rand.GetBytes($bytes)
    $rand.Dispose()
    $newClientSecret = [System.Convert]::ToBase64String($bytes)    
    $dtEnd = $secretStartDate.AddYears($secretValidity)
    New-MsolServicePrincipalCredential -AppPrincipalId $appClientId -Type Symmetric -Usage Sign -Value $newClientSecret -StartDate $secretStartDate  –EndDate $dtEnd
    New-MsolServicePrincipalCredential -AppPrincipalId $appClientId -Type Symmetric -Usage Verify -Value $newClientSecret   -StartDate $secretStartDate  –EndDate $dtEnd
    New-MsolServicePrincipalCredential -AppPrincipalId $appClientId -Type Password -Usage Verify -Value $newClientSecret   -StartDate $secretStartDate  –EndDate $dtEnd    
    
    $newkey.ClientId = $appClientId
    $newkey.ClientSecret = $newClientSecret
     
    $newkey | Out-File "$ScriptDir\Secret_New.txt"
    Write-Host "New Secret Generated."
}
  

#replace with your clientId
$appClientId = '041bf128-4442-45aa-bb37-d57167sa080b'
CreateNewClientSecret($appClientId)
Write-Host "Successfully Created ClientSecret for ClientId $appClientId"