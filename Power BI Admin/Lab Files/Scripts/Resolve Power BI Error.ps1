Login-PowerBI

## Try with a bad id to produce an error
$badId = 'not a guid'
Get-PowerBIWorkspace -Id $badId -Scope Organization

Resolve-PowerBIError -Last 
