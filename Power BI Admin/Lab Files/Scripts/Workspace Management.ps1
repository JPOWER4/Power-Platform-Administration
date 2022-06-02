$login = Login-PowerBI

## Filter for deleted workspaces that can be recovered (i.e. v2 workspaces only)
$deletedWorkspaces = Get-PowerBIWorkspace -Deleted -Scope Organization -Filter "type eq 'Workspace'"

## Recover the first one by assigning it to the current (admin) user.
$newName = 'Restored Workspace'
Restore-PowerBIWorkspace -Scope Organization -Id $deletedWorkspaces[0].id -RestoredName $newName -AdminUserPrincipalName $login.UserName 
