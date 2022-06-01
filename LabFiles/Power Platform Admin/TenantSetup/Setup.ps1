#start
#
####
#   Run  Start-AdminInADay-Setup or You must update the information in the following section prior to running and then run Start-AdminInADay-Setup-HardCoded
#
#   V3.0 - 10/25/2019 - Updated for new Admin in a day
#   V3.1 - 09/8/2020 - infer admin api from region
#
####


   $Tenant = "jenkinsnsfs"
 

   $CDSlocation = "india"
   
   #This is the number of lab users to create - you must have enough licenses and storage to support this number
   $LabAdminCount = 2

   $LabAdminPassword = "!passw0rdo1"

   #change if you want to use a different type of license for employee 
   $labemployeelicense =":POWERAPPS_PER_USER"
   ###$labemployeelicense =":POWERFLOW_P2"


####
#   End of the configuraiton section
####

Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force 
Install-Module -Name Microsoft.PowerApps.PowerShell  -Scope CurrentUser -AllowClobber -Force 

Install-Module Microsoft.Xrm.OnlineManagementAPI -Scope CurrentUser
Install-Module -Name Microsoft.Xrm.Data.Powershell -Scope CurrentUser

Install-Module -Name MSOnline -Scope CurrentUser -RequiredVersion 1.1.166.0 
Install-module azuread -Scope CurrentUser

Import-Module Microsoft.PowerShell.Utility 


[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;



Write-Host "### Prepare to run Start-AdminInADay-Setup ###" 
Write-Host ""
Write-Host "  Start-AdminInADay-Setup -TenantName 'MX60265ABC'  -CDSLocation 'unitedstates' -UserCount 10 " -ForegroundColor Green     
Write-Host "  Parameters details for Start-AdminInADay-Setup:"
Write-Host "     TenantName : This is the name portion of name.onmicrosoft.com" -ForegroundColor Green  
Write-Host "     CDSLocation: This must match be appropriate for Region e.g. US = unitedstates"  -ForegroundColor Green
Write-Host "     UserCount: This is a number between 1 and 75 that is attending your event"  -ForegroundColor Green
Write-Host "     You can find out your tenant region by running running Get-MsolCompanyInformation and looking at CountryLetterCode" -ForegroundColor Green
Write-Host ""
Write-Host "### Ready for you to run Start-AdminInADay-Setup ###" 

function Start-AdminInADay-Setup
{
    <#
    .SYNOPSIS 
      Configure a tenant for running an admin in a day workshop
    .EXAMPLE
     Start-AdminInADay-Setup -TenantName 'MX60265ABC'  -CDSLocation 'unitedstates' -UserCount 10 -APIUrl 'https://admin.services.crm.dynamics.com'
     
     TenantName : This is the name portion of name.onmicrosoft.com     
     CDSLocation: This must match be appropriate for Region e.g. US = unitedstates
     UserCount: This is a number between 1 and 75 that is attending your event
     APIUrl : You can find the url for your region here if not in US - https://docs.microsoft.com/en-us/dynamics365/customer-engagement/developer/online-management-api/get-started-online-management-api
     Restart : True or False - use this if you rerun to avoid doing things like deleting all users
    #>
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantName,
    [Parameter(Mandatory = $false)]
    [string]$CDSlocation="unitedstates",
    [Parameter(Mandatory = $true)]
    [int]$UserCount=1,
       [Parameter(Mandatory = $false)]
    [string]$APIUrl = "https://admin.services.crm.dynamics.com",
    [switch] $Restart = $false
    )



    Write-Host "Tenant:" $TenantName
    $Tenant = $TenantName;
    Write-Host "Region:" $Region
    $TenantRegioin = $Region;
    Write-Host "API Url:" $APIUrl
    $AdminAPIUrl = Get-AdminServiceUrl -CDSlocation $CDSlocation  
    Write-Host "CDS Location:" $CDSlocation
    Write-Host "User Count:" $UserCount
    $LabAdminCount = $UserCount

    Start-AdminInADay-Setup-HardCoded -Restart $Restart.IsPresent

}

function Start-AdminInADay-Setup-HardCoded
{
param ([bool] $Restart = $false)

    Write-Host "Setup Starting"

    $DomainName =$Tenant + ".onmicrosoft.com"

    $UserCredential = Get-Credential

    Write-Host "Connecting to Office 365..."
    Connect-MsolService -Credential $UserCredential
    Write-Host "Connecting to Azure AD..."
    Connect-AzureAD -Credential $UserCredential
    Write-Host "Connecting to PowerApps..."
    try{
        Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose
    }
    catch { 
       Write-Host "Error connecting to PowerApps, if error includes Cannot find overload for UserCredential please run CleanupOldModules.ps1 and retry this script"
       Read-Host -Prompt 'Press <Enter> to exit, then restart script with proper information'
       exit
    }
    

    Get-MsolAccountSku


        if ($Restart -eq $false)
        {
            $confirmDelete = Read-Host -Prompt 'Confirm disabling all accounts other than admin account(Y/N)'
            if ($confirmDelete -and $confirmDelete -eq 'Y') {
	            Write-Host "Proceeding to disable all users"
                Delete-DemoUsers;
            } else {
	            Write-Warning -Message "Not deleting all users"
                
            }
        }
        else
        {
            Write-Host "Not deleting all users"
        }
        
        $companyInfo = Get-MsolCompanyInformation        
        
        Create-LabAdminUsers -Tenant $Tenant -Count $LabAdminCount -TenantRegion $companyInfo.CountryLetterCode -password $LabAdminPassword -userprefix "labadmin"

        Setup-ServiceAccountsAndTestAccounts -TenantRegion $companyInfo.CountryLetterCode -password $LabAdminPassword

        Setup-Office365Logging

        Setup-ContosoEnvs

        Setup-ComplianceManagerRoles

        Setup-AddLabAdminToGroup

        Setup-AddLabAdminToSysAdmin-FixedEnvs

        Setup-DeviceOrderingSolution

        Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password

       # Create-CDSenvironment -namePrefix "Central Apps Test - " -CDSlocation $CDSlocation -password $LabAdminPassword

       # Create-CDSenvironment -namePrefix "Central Apps Prod - " -CDSlocation $CDSlocation -password $LabAdminPassword

       # Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password
        
       # Create-CDSDatabases

       # Setup-AddLabAdminToSysAdmin-StudentEnvs -namePrefix "Central Apps Test - "

       # Setup-AddLabAdminToSysAdmin-StudentEnvs -namePrefix "Central Apps Prod - "

        Add-LabAdminToDefaultEnvAdmins

        Setup-DLPPolicies


    

    

    Write-Host "Setup Ending"
}



function Delete-DemoUsers {

    Write-Host "***Removing Demo Users ****" -ForegroundColor Green

    Get-MsolUser | where {$_.UserPrincipalName -notlike 'admin*'}|Remove-MsolUser -Force

    Write-Host "****Old Users Deleted ****" -ForegroundColor Green
    Get-MsolUser |fl displayname,licenses

}



function Create-LabAdminUsers
{
   param
    (
    [Parameter(Mandatory = $true)]
    [string]$Tenant,
    [Parameter(Mandatory = $true)]
    [int]$Count,
    [Parameter(Mandatory = $false)]
    [string]$TenantRegion="GB",
    [Parameter(Mandatory = $false)]
    [string]$password=$UserPassword,
     [Parameter(Mandatory = $false)]
    [string]$userprefix="labadmin"
    )

    $DomainName = $Tenant+".onmicrosoft.com"


    
    Write-Host "Tenant: " $Tenant
    Write-Host "Domain Name: " $DomainName
    Write-Host "Count: " $Count
    Write-Host "Licence Plans: " (Get-MsolAccountSku).AccountSkuId
    Write-Host "TenantRegion: " $TenantRegion
    Write-Host "CDSlocation: " $CDSlocation
    Write-Host "password: " $password

  
    $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    
 
       Write-Host "creating users " -ForegroundColor Green
   
       for ($i=1;$i -lt $Count+1; $i++) {
       

            $firstname = "Lab"
            $lastname = "Admin" + $i
            $displayname = "Lab Admin " + $i
            $email = ($userprefix + $i + "@" + $DomainName).ToLower()
       
           $existingUser = Get-MsolUser -UserPrincipalName $email -ErrorAction SilentlyContinue

           if($existingUser -eq $Null)
           {

         
                 New-MsolUser -DisplayName $displayname -FirstName $firstname -LastName $lastname -UserPrincipalName $email -UsageLocation $TenantRegion -Password $password -LicenseAssignment $Tenant":POWERAPPS_PER_USER" -PasswordNeverExpires $true -ForceChangePassword $false  
         
                 Set-MsolUserLicense -UserPrincipalName $email -AddLicenses $Tenant":ENTERPRISEPACK" -Verbose
         
                #For E3 Set-MsolUserLicense -UserPrincipalName $email -AddLicenses $Tenant":ENTERPRISEPACK" -Verbose
                #For E5 Set-MsolUserLicense -UserPrincipalName $email -AddLicenses $Tenant":ENTERPRISEPREMIUM" -Verbose
            }
         
        }
        Write-Host "*****************Lab Users Created ***************" -ForegroundColor Green
        Get-MsolUser | where {$_.UserPrincipalName -like 'labadmin*'}|fl displayname,licenses

}


function Setup-ServiceAccountsAndTestAccounts {

 param
    (
   
    [Parameter(Mandatory = $true)]
    [string]$TenantRegion="GB",
      [Parameter(Mandatory = $false)]
    [string]$password=$UserPassword
   
    )
  
   Write-Host "***Starting - setting up Service Accounts ****" -ForegroundColor Green
   

   $firstname = "Service"
   $lastname = "Account"
   $displayname = "Service Account"
   $email = ("serviceaccount"+ "@" + $DomainName).ToLower()

   $existingUser = Get-MsolUser -UserPrincipalName $email -ErrorAction SilentlyContinue

   if($existingUser -eq $Null)
   {
            
       New-MsolUser -DisplayName $displayname -FirstName $firstname -LastName $lastname -UserPrincipalName $email -UsageLocation $TenantRegion -Password $password -LicenseAssignment $Tenant":POWERAPPS_PER_USER" -PasswordNeverExpires $true -ForceChangePassword $false  
 
       Set-MsolUserLicense -UserPrincipalName $email -AddLicenses $Tenant":ENTERPRISEPREMIUM" -Verbose
   
   }
   else
   {
      Set-MsolUserLicense -UserPrincipalName $email -AddLicenses $Tenant":ENTERPRISEPREMIUM" -Verbose
   }

   $firstname = "Lab"
   $lastname = "Back Office"
   $displayname = "Lab Back Office"
   $email = ("labbackoffice"+ "@" + $DomainName).ToLower()
       
   $existingUser = Get-MsolUser -UserPrincipalName $email -ErrorAction SilentlyContinue

   if($existingUser -eq $Null)
   {         
      New-MsolUser -DisplayName $displayname -FirstName $firstname -LastName $lastname -UserPrincipalName $email -UsageLocation $TenantRegion -Password $password -LicenseAssignment $Tenant":POWERAPPS_PER_USER" -PasswordNeverExpires $true -ForceChangePassword $false  
   }

   $firstname = "Lab"
   $lastname = "Employee" 
   $displayname = "Lab Employee"
   $email = ("labemployee" + "@" + $DomainName).ToLower()
      
   $license = $Tenant+$labemployeelicense         

   $existingUser = Get-MsolUser -UserPrincipalName $email -ErrorAction SilentlyContinue

   if($existingUser -eq $Null)
   {
      New-MsolUser -DisplayName $displayname -FirstName $firstname -LastName $lastname -UserPrincipalName $email -UsageLocation $TenantRegion -Password $password -LicenseAssignment $license -PasswordNeverExpires $true -ForceChangePassword $false  
   }

   $appGroup = Get-azureADGroup | where {$_.DisplayName -eq "Device Ordering App"} | Select-Object -first 1
   
   if (!$appGroup)
   {
     $appGroup = New-AzureADGroup -Description "Device Ordering App Users" -DisplayName "Device Ordering App" -MailEnabled $false -SecurityEnabled $true -MailNickName "DeviceOrderingUsers"
     Write-Host "Created new group " $appGroup.ObjectId
   }
   else
   {
      Write-Host "Found existing group " $appGroup.ObjectId
   }

   Write-Host "Delaying to allow users to be ready to add to groups"
   sleep 15

   $users = Get-MsolUser | where {$_.UserPrincipalName -like 'labemployee*'} | Sort-Object UserPrincipalName


    ForEach ($user in $users) { 

        write-host "adding user "  $user.UserPrincipalName  " to group "  $appGroup.DisplayName

        Add-AzureADGroupMember -ObjectId $appGroup.ObjectId -RefObjectId $user.ObjectId

        
    }

    $mdGroup = Get-azureADGroup | where {$_.DisplayName -eq "Device Procurement App"} | Select-Object -first 1
   
   if (!$mdGroup)
   {
      $mdGroup = New-AzureADGroup -Description "Backoffice Users" -DisplayName "Device Procurement App" -MailEnabled $false -SecurityEnabled $true -MailNickName "DeviceProcurement"
      Write-Host "Created new group " $mdGroup.ObjectId
   }
   else
   {
      Write-Host "Found existing group " $mdGroup.ObjectId
   }
   
   $users = Get-MsolUser | where {$_.UserPrincipalName -like 'labbackoffice*'} | Sort-Object UserPrincipalName


    ForEach ($user in $users) { 

        write-host "adding user "  $user.UserPrincipalName  " to group "  $mdGroup.DisplayName

        Add-AzureADGroupMember -ObjectId $mdGroup.ObjectId -RefObjectId $user.ObjectId

        
    }
    Write-Host "***Ending - setting up Service Accounts ****" -ForegroundColor Green
}


function Setup-Office365Logging {

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

    Import-PSSession $Session -DisableNameChecking

    Write-Host "Enabling Customizations"

    Enable-OrganizationCustomization

    Write-Host "Enabling Customizations - Done"

    Write-Host "Delaying to allow enabling customizations to take effect"
    sleep 15

    Write-Host "Setting Unified Audit Log Ingestion Enabled"

    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true 

    Write-Host "Setting Unified Audit Log Ingestion Enabled - Done"

    Remove-PSSession $Session
}

class NewEnvInfo {
    [string]$displayname
    [string]$location
    [string]$sku; `
`
    NewEnvInfo(
    [string]$displayname,
    [string]$location,
    [string]$sku
    ){
        $this.displayname = $displayname
        $this.location = $location
        $this.sku = $sku
    }
}


function Setup-ContosoEnvs{

    $newEnvList =@([NewEnvInfo]::new("Device Ordering Development",$CDSlocation,"Production"),
        [NewEnvInfo]::new("Power Platform COE",$CDSlocation,"Production"),
        [NewEnvInfo]::new("Thrive Hr - Prod",$CDSlocation,"Production"),
        [NewEnvInfo]::new("Thrive Hr - Dev",$CDSlocation,"Production"),
        [NewEnvInfo]::new("Thrive Hr - UAT",$CDSlocation,"Sandbox"),
        [NewEnvInfo]::new("Thrive Hr - Test",$CDSlocation,"Sandbox"),        
        [NewEnvInfo]::new("Trying CDS",$CDSlocation,"Trial"))
    
    Add-PowerAppsAccount -Username $UserCredential.UserName -Password $UserCredential.Password -Verbose

    ForEach ($newEnv in $newEnvList) { 

        $envQuery = $newEnv.displayname + "*"

        $envDevList = @(Get-AdminPowerAppEnvironment | where { $_.DisplayName -like $envQuery })         
        
        if ($envDevList.count -eq 0 ) { 

            Write-Host "Creating environment " $newEnv.displayname

            $devEnv = New-AdminPowerAppEnvironment -DisplayName  $newEnv.displayname -LocationName $newEnv.location -EnvironmentSku $newEnv.sku 

            Write-Host "Creating CDS " $newEnv.displayname

            New-AdminPowerAppCdsDatabase -EnvironmentName  $devEnv.EnvironmentName -CurrencyName USD -LanguageName 1033  -ErrorAction Continue -WaitUntilFinished $true

            Wait-ForCDSProvisioning -namePrefix $newEnv.displayname

        }
        else {

            Write-Host "Environment " $newEnv.displayname " already exists - skipping"

        }
    }


}
function Wait-ForCDSProvisioning{

param(
    [Parameter(Mandatory = $true)]
    [string]$namePrefix="Central Apps"
    )

        $searchPrefix = '*' + $namePrefix + '*'

        Write-host "Checking on provisioning status of CDS :" $searchPrefix
        Do  
        {
            
            $CDSenvs = @(Get-AdminPowerAppEnvironment | where { $_.DisplayName -like $searchPrefix -and $_.CommonDataServiceDatabaseProvisioningState -ne "Succeeded" })         
            
            
            if ($CDSenvs.count -gt 0)
            {
                Write-Host "There are" $CDSenvs.count "CDS provisionings left " $searchPrefix " - Waiting 30 seconds "
                Start-Sleep -s 30
            }
        } While ($CDSenvs.count -gt 0)
}


function Setup-ComplianceManagerRoles{

#Set-ExecutionPolicy RemoteSigned
   
   $userprefix ='labadmin*'

   $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

   Import-PSSession $Session -DisableNameChecking -AllowClobber

   Write-Host "Adding compliance manager role to users"
   
   $users = Get-MsolUser | where {$_.UserPrincipalName -like $userprefix} | Sort-Object UserPrincipalName


    ForEach ($user in $users) { 
    

    Add-RoleGroupMember “Compliance Management” -Member  $user.UserPrincipalName.Split('@')[0]

        
        }

    Remove-PSSession $Session

}

function Setup-AddLabAdminToGroup
{

    Write-Host "Starting add labadmin users to Lab Admin Team group"

   $userprefix ='labadmin*'

   $adminGroup = Get-azureADGroup | where {$_.DisplayName -eq "Lab Admin Team"} | Select-Object -first 1

   if (!$adminGroup)
   {
        $adminGroup = New-AzureADGroup -Description "Lab Admin Team" -DisplayName "Lab Admin Team" -MailEnabled $false -SecurityEnabled $true -MailNickName "LabAdmins"
        Write-Host "Created new group " $adminGroup.ObjectId
   }
   else
   {
        Write-Host "Found existing group " $adminGroup.ObjectId
   }
   
   $users = Get-MsolUser | where {$_.UserPrincipalName -like $userprefix} | Sort-Object UserPrincipalName

   $existingMembers = Get-AzureADGroupMember -ObjectId $adminGroup.ObjectId | Select -ExpandProperty UserPrincipalName


    ForEach ($user in $users) { 

        if (!$existingMembers -contains $user.UserPrincipalName)
        {

            write-host "adding user "  $user.UserPrincipalName  " to group "  $adminGroup.DisplayName

            Add-AzureADGroupMember -ObjectId $adminGroup.ObjectId -RefObjectId $user.ObjectId
        }
        else
        {
            write-host "user "  $user.UserPrincipalName  " is already a member of "  $adminGroup.DisplayName
        }

        
    }
    Write-Host "Ending add labadmin users to Lab Admin Team group"
}

function Setup-AddLabAdminToSysAdmin-FixedEnvs{

    $userprefix ='labadmin*'

    Write-Host "Starting to add lab admin to dev environment as sysadmin"

    $role = 'System Administrator'

    
    try
        {
            $cdsInstances = Get-CrmInstances -ApiUrl $AdminAPIUrl -Credential $UserCredential
 
            }
        Catch
        {
            $ErrorMessage = $_.Exception.Message        
            write-output $ErrorMessage
            Write-Output "Trying again"
            $cdsInstances = Get-CrmInstances -ApiUrl $AdminAPIUrl -Credential $UserCredential
        
        }


    $envlist=$cdsInstances.Where({$_.EnvironmentType  -ne 'Default'}).Where({$_.FriendlyName -like '*Thrive*' -or $_.FriendlyName -like '*My Sandbox*' -or $_.FriendlyName -like '*Trying*' -or $_.FriendlyName -like '*Device Ordering Development*' -or $_.FriendlyName -like '*Power Platform COE*' })

    Write-Host "Found " $envlist.length " environments to process"

        ForEach ($environemnt in $envlist) { 
     
         Write-Host "Processing environment :" $environemnt.FriendlyName


         $conn = Connect-CrmOnline -Credential $UserCredential -ServerUrl $environemnt.ApplicationUrl -ForceOAuth 
         $conn.IsReady,$conn.ConnectedOrgFriendlyName
    
         while($conn.IsReady -eq $false)
         {
             Write-Host "Delaying 5 seconds to allow connection to " $environemnt.ApplicationUrl
             sleep 5
         }
   
        $users = Get-CrmRecords `
               -EntityLogicalName systemuser `
               -Fields domainname,systemuserid, fullname `
               -conn $conn

     $users = $users.CrmRecords | where {$_.domainname -like $userprefix} | Sort-Object domainname


        ForEach ($user in $users) { 

            write-host "adding user "  $user.fullname  " to group sysadmin"

                try
            {
                Add-CrmSecurityRoleToUser `
                   -UserId $user.systemuserid `
                   -SecurityRoleName $role `
                   -conn $conn
 
             }
            Catch
            {
                $ErrorMessage = $_.Exception.Message        
                write-output $ErrorMessage
        
            }
   

        
            }

    
        }   
        Write-Host "Ending add lab admin to dev environment as sysadmin"
}

function Setup-DeviceOrderingSolution{


    Write-Host "Starting import of device admin solution"

    $adminGroup = Get-azureADGroup | where {$_.DisplayName -eq "Lab Admin Team"} | Select-Object -first 1

    $role = 'System Administrator'
      try
        {
            $cdsInstances = Get-CrmInstances -ApiUrl $AdminAPIUrl -Credential $UserCredential
 
            }
        Catch
        {
            $ErrorMessage = $_.Exception.Message        
            write-output $ErrorMessage
            Write-Output "Trying again"
            $cdsInstances = Get-CrmInstances -ApiUrl $AdminAPIUrl -Credential $UserCredential
        
        }


    $envlist=$cdsInstances.Where({$_.EnvironmentType  -ne 'Default'}).Where({$_.FriendlyName -like  '*Device Ordering Development*' })

    Write-Host "Found " $envlist.length " environments to process"

    ForEach ($environemnt in $envlist) { 
     
         Write-Host "Processing environment :" $environemnt.FriendlyName


         $conn = Connect-CrmOnline -Credential $UserCredential -ServerUrl $environemnt.ApplicationUrl
         $conn.IsReady,$conn.ConnectedOrgFriendlyName
    
        $solutionPath = $PSScriptRoot + "\ContosoDeviceOrderManagement_1_0_0_1.zip"

        Write-Host "Importing " $solutionPath

        Import-CrmSolution -conn $conn -SolutionFilePath $solutionPath -Verbose
    
     }   

     Write-Host "Giving Can Edit permission to labadmins"

     $devEnv = Get-AdminPowerAppEnvironment | where {$_.DisplayName -like 'Device Ordering Development*'}       

     $devApp = get-adminpowerapp -EnvironmentName  $devEnv.EnvironmentName -Filter 'Device Ordering App'
        
     Set-AdminPowerAppRoleAssignment -PrincipalType Group -PrincipalObjectId $adminGroup.ObjectId -RoleName CanViewWithShare -AppName $devApp.AppName -EnvironmentName $devEnv.EnvironmentName
   
     Write-Host "Ending import of device admin solution"
}

function Create-CDSenvironment {

    param(
    [Parameter(Mandatory = $true)]
    [string]$namePrefix="Central Apps Test - ",
    [Parameter(Mandatory = $false)]
    [string]$password=$UserPassword,
    [Parameter(Mandatory = $false)]
    [string]$CDSlocation="canada"
    )

    $userprefix ='labadmin*'

    $starttime= Get-Date -DisplayHint Time
    Write-Host " Starting CreateCDSEnvironment :" $starttime   -ForegroundColor Green

    $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $users = Get-MsolUser | where {$_.UserPrincipalName -like $userprefix } | Sort-Object UserPrincipalName

    
    ForEach ($user in $users) { 
        $envDev=$null
        $envProd=$null

        if ($user.isLicensed -eq $false)
        {
            write-host " skiping user " $user.UserPrincipalName " he is not licensed" -ForegroundColor Red
            continue
        }

        #write-host " switching to user " $user.UserPrincipalName 

        #Add-PowerAppsAccount -Username $user.UserPrincipalName -Password $securepassword -Verbose

        write-host " creating environment for user " $user.UserPrincipalName 
         
         $envDisplayname = $namePrefix + $user.UserPrincipalName.Split('@')[0] 
         $envDisplayname

         $envQuery = $envDisplayname + "*"
         
         $envDevList = @(Get-AdminPowerAppEnvironment | where { $_.DisplayName -like $envQuery })         
        
        if ($envDevList.count -eq 0 ) { 
       
            $envDev = New-AdminPowerAppEnvironment -DisplayName  $envDisplayname -LocationName $CDSlocation -EnvironmentSku Production -Verbose
            
       
            Write-Host " Created CDS Environment with id :" $envDev.EnvironmentName   -ForegroundColor Green 
        }
        else{
            Write-Host " Skipping CDS Environment with id :" $envDev.EnvironmentName " it already exists"  -ForegroundColor Green 
        }
      
       
         
    }
    $endtime = Get-Date -DisplayHint Time
    $duration = $("{0:hh\:mm\:ss}" -f ($endtime-$starttime))
    Write-Host "End of CreateCDSEnvironment at : " $endtime "  Duration: " $duration   -ForegroundColor Green

}



function Create-CDSDatabases {

        $starttime= Get-Date -DisplayHint Time
        Write-Host "Starting CreateCDSDatabases :" $starttime   -ForegroundColor Green

        $CDSenvs = Get-AdminPowerAppEnvironment | where { $_.DisplayName -like "Central Apps*" -and $_.commonDataServiceDatabaseType -eq "none"} | Sort-Object displayname
        
        Write-Host "creating CDS databases for following environments :
          " $CDSenvs.DisplayName "
        ****************************************************************
        ****************************************************************" -ForegroundColor Green

        ForEach ($CDSenv in $CDSenvs) { 
         $CDSenv.EnvironmentName
         Write-Host "creating CDS databases for:" $CDSenv.DisplayName " id:" $CDSenv.EnvironmentName -ForegroundColor Yellow
           
             New-AdminPowerAppCdsDatabase -EnvironmentName  $CDSenv.EnvironmentName -CurrencyName USD -LanguageName 1033 -Verbose -ErrorAction Continue -WaitUntilFinished $false
           
        }

        $endtime = Get-Date -DisplayHint Time
        $duration = $("{0:hh\:mm\:ss}" -f ($endtime-$starttime))
        Write-Host "End of CreateCDSDatabases at : " $endtime "  Duration: " $duration   -ForegroundColor Green
        
}

function Setup-AddLabAdminToSysAdmin-StudentEnvs{

    param(
    [Parameter(Mandatory = $true)]
    [string]$namePrefix="Central Apps Test - "
    )

    Write-Host "Starting add lab admin to test environment as sysadmin using " $AdminAPIUrl

    $role = 'System Administrator'

    try
    {
        $cdsInstances = Get-CrmInstances -ApiUrl $AdminAPIUrl -Credential $UserCredential
 
        }
    Catch
    {
        $ErrorMessage = $_.Exception.Message        
        write-output $ErrorMessage
        Write-Output "Trying again"
        $cdsInstances = Get-CrmInstances -ApiUrl $AdminAPIUrl -Credential $UserCredential
        
    } 


    $envlist=$cdsInstances.Where({$_.EnvironmentType  -ne 'Default'}).Where({$_.FriendlyName -like '*Central Apps*' })

    Write-Host "Found " $envlist.length " environments to process"

        ForEach ($environemnt in $envlist) { 
     
         Write-Host "Processing environment :" $environemnt.FriendlyName


         $conn = Connect-CrmOnline -Credential $UserCredential -ServerUrl $environemnt.ApplicationUrl
         $conn.IsReady,$conn.ConnectedOrgFriendlyName
    
   
        $users = Get-CrmRecords `
               -EntityLogicalName systemuser `
               -Fields domainname,systemuserid, fullname `
               -conn $conn
              
        $compareString =$conn.ConnectedOrgFriendlyName -replace $namePrefix,"*" 
        $compareString = $compareString +  "*"
        Write-Host "comparing " $compareString

     $selectedUsers = $users.CrmRecords | where { $_.domainname -like $compareString} | Sort-Object domainname


        ForEach ($user in $selectedUsers) { 

            write-host "adding user "  $user.fullname  " to group sysadmin"

                try
            {
                Add-CrmSecurityRoleToUser `
                   -UserId $user.systemuserid `
                   -SecurityRoleName $role `
                   -conn $conn
 
             }
            Catch
            {
                $ErrorMessage = $_.Exception.Message        
                write-output $ErrorMessage
        
            }
   

        
            }

    
        }   
        Write-Host "Ending add lab admin to test environment as sysadmin"
}

function Add-LabAdminToDefaultEnvAdmins{

    Write-Host "Starting making labadmins environment admins on default environment"

    $userprefix ='labadmin*'

    $defEnv = Get-AdminPowerAppEnvironment | where {$_.EnvironmentType -eq 'Default'};
    
   
    $users = Get-MsolUser | where {$_.UserPrincipalName -like $userprefix} | Sort-Object UserPrincipalName


    ForEach ($user in $users) { 
    
        Set-AdminPowerAppEnvironmentRoleAssignment -EnvironmentName $defEnv.EnvironmentName -RoleName EnvironmentAdmin -PrincipalType User -PrincipalObjectId $user.ObjectId
        
    }

    Write-Host "Ending making labadmins environment admins on default environment"

}

function Setup-DLPPolicies{

    Write-Host "Starting to create DLPs"

	$dp1 = get-AdminDLPPolicy  -Filter "Contoso Global DLP" 

    if ($dp1 -eq $null ){

	    $dp1 = New-AdminDlpPolicy -DisplayName "Contoso Global DLP" 
    }
    


	Add-ConnectorToBusinessDataGroup -PolicyName $dp1.PolicyName –ConnectorName 'shared_commondataservice' 
	Add-ConnectorToBusinessDataGroup -PolicyName $dp1.PolicyName –ConnectorName 'shared_sharepointonline' 
    Add-ConnectorToBusinessDataGroup -PolicyName $dp1.PolicyName –ConnectorName 'shared_approvals' 
    Add-ConnectorToBusinessDataGroup -PolicyName $dp1.PolicyName –ConnectorName 'shared_office365' 

	$dp2 = get-AdminDLPPolicy  -Filter "Thrive Exception DLP" 

    if ($dp2 -eq $null ){

	    $dp2 = New-AdminDlpPolicy -DisplayName "Thrive Exception DLP" 
    }

    Add-ConnectorToBusinessDataGroup -PolicyName $dp2.PolicyName –ConnectorName 'shared_commondataservice' 
	Add-ConnectorToBusinessDataGroup -PolicyName $dp2.PolicyName –ConnectorName 'shared_sharepointonline' 
	Add-ConnectorToBusinessDataGroup -PolicyName $dp2.PolicyName –ConnectorName 'shared_teams' 
	Add-ConnectorToBusinessDataGroup -PolicyName $dp2.PolicyName –ConnectorName 'shared_office365users' 
	Add-ConnectorToBusinessDataGroup -PolicyName $dp2.PolicyName –ConnectorName 'shared_office365' 


    #force to single environment so DLP doesn't impact the labs
    #$envInclude = @(Get-AdminPowerAppEnvironment | where { $_.DisplayName -like '*Thrive Hr -*' }) | Select-Object -first 1
    $envInclude = @(Get-AdminPowerAppEnvironment | where { $_.DisplayName -like '*Thrive Hr -*' }) | Select-Object -Property EnvironmentName
    $envIncludeList=""
    $envInclude | %{$envIncludeList += ($(if($envIncludeList){","}) + $_.EnvironmentName )}
    $envExcludeList=""
    $envExclude = @(Get-AdminPowerAppEnvironment | where { $_.DisplayName -like '*Thrive Hr -*' -or $_.DisplayName -like '*COE*'}) | Select-Object -Property EnvironmentName
    $envExclude | %{$envExcludeList += ($(if($envExcludeList){","}) + $_.EnvironmentName )}
    Set-AdminDlpPolicy -PolicyName $dp1.PolicyName -FilterType Exclude -Environments $envExcludeList
    Set-AdminDlpPolicy -PolicyName $dp2.PolicyName -FilterType Include -Environments $envIncludeList


    Write-Host "Ending create DLPs"

}

function Get-AdminServiceUrl
{
param(   
    [Parameter(Mandatory = $false)]
    [string]$CDSlocation="unitedstates",
    [Parameter(Mandatory = $false)]
    [string]$APIUrl="https://admin.services.crm.dynamics.com"
    )
   $result = switch ( $CDSlocation )
    {
        "unitedstates" { 'https://admin.services.crm.dynamics.com'    }
        "southamerica" { 'https://admin.services.crm2.dynamics.com'    }
        "canada" { 'https://admin.services.crm3.dynamics.com'    }
        "europe" { 'https://admin.services.crm4.dynamics.com'    }
        "asia" { 'https://admin.services.crm5.dynamics.com'    }
        "australia" { 'https://admin.services.crm6.dynamics.com'    }
        "japan" { 'https://admin.services.crm7.dynamics.com'    }
        "india" { 'https://admin.services.crm8.dynamics.com'    }
        "unitedkingdom" { 'https://admin.services.crm11.dynamics.com'    }
        "france" { 'https://admin.services.crm12.dynamics.com'    }
        default { $APIUrl    }
       
    }

    return $result
}
