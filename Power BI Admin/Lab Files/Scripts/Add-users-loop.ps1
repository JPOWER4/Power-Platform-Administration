## Requires the Azure AD 2.0 cmdlets
## Install-Module -Name AzureAD

# Set-ExecutionPolicy RemoteSigned

$UserCredential = Get-Credential
Connect-AzureAD -credential $UserCredential

For ($i=1; $i -le 401; $i++) {
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password = "P@ssw0rd"

    $displayName = "Ready User" + $i
    $upn = "readyuser" + $i + "@msreadydemo.onmicrosoft.com"
    $mb = "readyuser" + $i

    New-AzureADUser -DisplayName $displayName -PasswordProfile $PasswordProfile -UserPrincipalName $upn -AccountEnabled $true -MailNickName $mb -UsageLocation "US"
    }


