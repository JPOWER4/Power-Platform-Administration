## Requires the Azure AD 2.0 cmdlets
## Install-Module -Name AzureAD

# Set-ExecutionPolicy RemoteSigned

$UserCredential = Get-Credential

## Create the session to Exchange Online
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

## Import the Exchange Online commands
Import-PSSession $Session

$csvFile = "c:\temp\auditlog.csv"
Search-UnifiedAuditLog -StartDate 1/1/2017 -EndDate 2/17/2018 -RecordType PowerBI -ResultSize 5000 | Export-Csv $csvFile