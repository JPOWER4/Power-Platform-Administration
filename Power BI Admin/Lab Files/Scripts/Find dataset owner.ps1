Login-PowerBI
$datasetIds = Get-PowerBIDataset -Scope Organization | Foreach {$dsId = $_.Id; Get-PowerBIDatasource -DatasetId $dsId -Scope Organization | Where-Object {$_.DatasourceType -eq 'Sql' -and ($_.ConnectionDetails.Server -like 'sqldb01' -and $_.ConnectionDetails.Database -like 'sales')} | Foreach { $dsId }}
$reports = $datasetIds | Foreach { Get-PowerBIReport -Filter "datasetId eq '$_'" -Scope Organization }
$owners = $datasetIds | Foreach { Get-PowerBIDataset -Id $_ -Scope Organization } | foreach { $_.ConfiguredBy } 
