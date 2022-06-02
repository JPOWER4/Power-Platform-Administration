# Install the On-Premises Data Gateway PowerShell module
# This requires pre-release currently
#
# Install-Module -Name OnPremisesDataGatewayMgmt -AllowPrerelease

# Cluster ID: f16c0ea9-c0af-418e-aab2-59f44e07c42b

Login-OnPremisesDataGateway -EmailAddress "asaxton@guyinacube.com"

# Get a list of clusters
Get-OnPremisesDataGatewayClusters

# Get a list of gateways for a given cluster
Get-OnPremisesDataGatewayClusterInfo

# Get the status of gateways
Get-OnPremisesDataGatewayStatus