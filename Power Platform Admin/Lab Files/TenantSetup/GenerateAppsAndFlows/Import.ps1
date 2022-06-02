
#Setup
Import-Module .\ImportExport.psm1 -Force
Import-Module .\PowerApps-RestClientModule.psm1 -Force
Import-Module .\PowerApps-AuthModule.psm1 
Import-Module .\Microsoft.IdentityModel.Clients.ActiveDirectory.dll
Import-Module .\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll
Import-Module .\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll
Import-Module .\Microsoft.PowerApps.Administration.PowerShell.psm1 -Force

$TenantName="M365x621622.onmicrosoft.com"
$pass = ConvertTo-SecureString "test@word1" -AsPlainText -Force

$environmentDisplayName = "User and Team Productivity"

$createApps=$true
$createFlows=$true
$assignApps=$true
$userCount=25

$ApiVersion = "2016-11-01"

Add-PowerAppsAccount -Username "admin@M365x621622.onmicrosoft.com" -Password $pass

if ($createFlows -eq $true)
{
# #----------------------Import the flow---------------------------------#

Write-Host "Select target environment for importing your flow package"


$targetEnvironment = Get-AdminPowerAppEnvironment "*$environmentDisplayName*"
$targetEnvironmentName = $targetEnvironment.EnvironmentName


$importPackageFilePath = ($pwd).path + "\flowExportPackage.zip"

Write-Host "------------------------Importing the flow------------------------"

$flowNames = Get-Content -Path .\FlowNames.txt
foreach($fname in $flowNames)
{
    Write-Host "Creating " $fname
    $resourceName = $fname

    $importAppResponse = Import-Package -EnvironmentName $targetEnvironmentName -ApiVersion $ApiVersion -ImportPackageFilePath $importPackageFilePath -DefaultToExportSuggestions $true -AutoSelectDataSourcesOnImport $true -ResourceName $resourceName;

    Write-Host "Import complete"

    $flowName = $null

    foreach ($resource in Get-Member -InputObject $importAppResponse.properties.resources -MemberType NoteProperty)
    {
        $property = 'Name'
        $propertyvalue = $resource.$property

        if ($importAppResponse.properties.resources.$propertyvalue.type -eq "Microsoft.Flow/flows")
        {
            $flowName = $importAppResponse.properties.resources.$propertyvalue.name
        }
    }
    Write-Host "Found flow name = $flowName"
} 

}
if ($createApps -eq $true)
{

#----------------------Import the app---------------------------------#

Write-Host "Select target environment for importing your app package"


$targetEnvironment = Get-AdminPowerAppEnvironment "*$environmentDisplayName*"
$targetEnvironmentName = $targetEnvironment.EnvironmentName

$importPackageFilePath = ($pwd).path + "\appExportPackage.zip"

Write-Host "------------------------Importing the app------------------------"

$appNames = Get-Content -Path .\AppNames.txt
foreach($aName in $appNames)
{
    Write-Host $aName
    $resourceName = $aName
    try
    {
    Write-Host "Import starting"
        $importAppResponse = Import-Package -EnvironmentName $targetEnvironmentName -ApiVersion $ApiVersion -ImportPackageFilePath $importPackageFilePath -DefaultToExportSuggestions $true -AutoSelectDataSourcesOnImport $true -ResourceName $resourceName;

        Write-Host "Import complete"

        $appName = $null
        foreach ($resource in Get-Member -InputObject $importAppResponse.properties.resources -MemberType NoteProperty)
        {
            $property = 'Name'
            $propertyvalue = $resource.$property
        
            if ($importAppResponse.properties.resources.$propertyvalue.type -eq "Microsoft.PowerApps/apps")
            {
                $appName = $importAppResponse.properties.resources.$propertyvalue.name
            }
        }
        Write-Host "Found $resourceName with an appid = $appName"
        }
        catch
        {
            Write-Host "Error importing  $resourceName "
            Write-Host $_
        }

}
} 
if ($assignApps -eq $true)
{
    for ($i=1;$i -lt $UserCount+1; $i++) {
      $labadminpass = ConvertTo-SecureString "test@word1" -AsPlainText -Force
      $labAdminUser = "labadmin$($i)@$($TenantName)"
      Write-Host "Processing $labAdminUser"
      Add-PowerAppsAccount -Username $labAdminUser -Password $labadminpass
      $labAdminFilter = "Lab Admin $($i)"
  
      $labAdminApp = Get-AdminPowerApp  -Filter $labAdminFilter | Select-Object -First 1
      
      Set-AdminPowerAppOwner –AppName $labAdminApp.AppName -AppOwner $Global:currentSession.userId –EnvironmentName $targetEnvironmentName
    }
}

