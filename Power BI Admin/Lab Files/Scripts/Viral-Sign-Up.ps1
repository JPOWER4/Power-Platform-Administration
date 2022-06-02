## Requires the Azure AD 2.0 cmdlets
## Install-Module -Name AzureAD

# Set-ExecutionPolicy RemoteSigned

$msolcred = get-credential 
connect-msolservice -credential $msolcred

# List the current setting value
Get-MsolCompanyInformation | fl AllowAdHocSubscriptions

# Set to $false to turn off viral sign up. Set to $true to enable it
Set-MsolCompanySettings -AllowAdHocSubscriptions $false