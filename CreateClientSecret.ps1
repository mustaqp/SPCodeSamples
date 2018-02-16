<# 
Code Example Disclaimer:Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED 'AS IS'-This is intended as a sample of how code might be written for a similar purpose and you will need to make changes to fit to your requirements. -This code has not been tested.  This code is also not to be considered best practices or prescriptive guidance.  -No debugging or error handling has been implemented.-It is highly recommended that you FULLY understand what this code is doing  and use this code at your own risk.

Need Azure Active Directory Powershell Module
https://support.office.com/en-us/article/Connect-PowerShell-to-Office-365-services-06a743bb-ceb6-49a9-a61d-db4ffdf54fa6

Also Need Online Sign in assistant
https://www.microsoft.com/en-us/download/details.aspx?id=39267

Use Case: Low Trust Provider Hosted Apps or Add-ins require Client Secret, which are valid for either 1 or 3 years. Once they Expire, the apps will stop working and you need to generate new once for that particular appId or clientId. This PowerShell Script connects to Azure Active Directory and creates a client secret which is valid for 3 years. Note that each client secret contains 3 keys. The new Secret will get saved in Secret_New.txt at same location from where you run this powershell. Save this clientsecret, along with clientid or appid. This will be needed in web.config of your PHA and for future references. 

Usage: Open the file and update the value of $appClientId with your clientId or AppId for which you want to generate Secret. 
Save the ps1.
Open Windows Powershell in administrative mode and cd to the location where you save this script.
Run the script. It will prompt for your onmicrosoft account and password. Once authentication succeeds you will see Secret_New.txt at same location from where the script was ran. 
#> 
 
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
$appClientId = 'your client id guid'
CreateNewClientSecret($appClientId)
Write-Host "Successfully Created ClientSecret for ClientId $appClientId"

