Login-PowerBI
$workspaces = Get-PowerBIWorkspace -Scope Organization
$workspaces | Export-Csv "workspaces.csv" -NoTypeInformation

@("reports", "dashboards", "datasets") | foreach {
                $csvFile = $_ + ".csv"
                if(Test-Path $csvFile){ Remove-Item $csvFile }
            }

foreach($workspace in $workspaces) 
{
    $reports = Get-PowerBIReport -WorkspaceId $workspace.id -Scope Organization;
    $reports | Add-Member -NotePropertyName workspaceId -NotePropertyValue $workspace.id;
    $reports | Export-Csv "reports.csv" -NoTypeInformation -Append;

    $dashboards = Get-PowerBIDashboard -WorkspaceId $workspace.id -Scope Organization;
    $dashboards | Add-Member -NotePropertyName workspaceId -NotePropertyValue $workspace.id;
    $dashboards | Export-Csv "dashboards.csv" -NoTypeInformation -Append;

    $datasets = Get-PowerBIDataset -WorkspaceId $workspace.id -Scope Organization;
    $datasets | Add-Member -NotePropertyName workspaceId -NotePropertyValue $workspace.id;
    $datasets | Export-Csv "datasets.csv" -NoTypeInformation -Append;
} 
