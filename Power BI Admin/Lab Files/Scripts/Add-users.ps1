## Requires the Azure AD 2.0 cmdlets
## Install-Module -Name AzureAD

# Set-ExecutionPolicy RemoteSigned

$UserCredential = Get-Credential
Connect-AzureAD -credential $UserCredential

# Create the objects we'll need to add and remove licenses
$license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses

# Find the SkuID of the license we want to add - in this example we'll use the O365_BUSINESS_PREMIUM license
$license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value "ENTERPRISEPREMIUM" -EQ).SkuID

# Set the Office license as the license we want to add in the $licenses object
$licenses.AddLicenses = $license

# Password to use for new users
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = "P@ssw0rd"

# **** John Doe ****
New-AzureADUser -DisplayName "John Doe" -PasswordProfile $PasswordProfile -UserPrincipalName "johndoe@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "johndoe" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "johndoe@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses


# **** Jane Doe ****
New-AzureADUser -DisplayName "Jane Doe" -PasswordProfile $PasswordProfile -UserPrincipalName "janedoe@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "janedoe" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "janedoe@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses


# **** Anakin Skywalker ****
New-AzureADUser -DisplayName "Anakin Skywalker" -PasswordProfile $PasswordProfile -UserPrincipalName "anakinskywalker@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "vader" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "anakinskywalker@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses


# **** Luke Skywalker ****
New-AzureADUser -DisplayName "Luke Skywalker" -PasswordProfile $PasswordProfile -UserPrincipalName "lukeskywalker@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "masterskywalker" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "lukeskywalker@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses


# **** Leia Organa ****
New-AzureADUser -DisplayName "Leia Organa" -PasswordProfile $PasswordProfile -UserPrincipalName "leiaorgana@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "princessleia" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "leiaorgana@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses


# **** Han Solo ****
New-AzureADUser -DisplayName "Han Solo" -PasswordProfile $PasswordProfile -UserPrincipalName "hansolo@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "nerfherder" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "hansolo@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses


# **** Chewbacca ****
New-AzureADUser -DisplayName "Chewbacca" -PasswordProfile $PasswordProfile -UserPrincipalName "chewbacca@readypbideploy.onmicrosoft.com" -AccountEnabled $true -MailNickName "chewie" -UsageLocation "US"
# Call the Set-AzureADUserLicense cmdlet to set the license.
Set-AzureADUserLicense -ObjectId "chewbacca@readypbideploy.onmicrosoft.com" -AssignedLicenses $licenses