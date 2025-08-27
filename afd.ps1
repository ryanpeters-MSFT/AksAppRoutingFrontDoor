. .\vars.ps1

$frontDoorProfile = "aksfrontdoor"
$endpointName = "akspublicendpoint"
$originGroupName = "aks-origin-group"
$originName = "aks-origin"
$routeName = "aksroute"

# create the front door profile
az afd profile create `
    -g $group `
    --profile-name $frontDoorProfile `
    --sku Premium_AzureFrontDoor

# create the front door endpoint
az afd endpoint create `
    -g $group `
    --profile-name $frontDoorProfile `
    --endpoint-name $endpointName `
    --enabled-state Enabled

# get the node resource group
$nodeGroup = az aks show -g $group -n $cluster --query nodeResourceGroup -o tsv

# get the private link ID
$privateLinkId = az network private-link-service show `
    -g $nodeGroup `
    -n akspls `
    -o tsv --query id

# create the origin group
az afd origin-group create `
    -g $group `
    --profile-name $frontDoorProfile `
    --origin-group-name $originGroupName `
    --probe-request-type GET `
    --probe-protocol Http `
    --probe-interval-in-seconds 120 `
    --probe-path "/" `
    --sample-size 4 `
    --successful-samples-required 3 `
    --additional-latency-in-milliseconds 50

# get the default hostname for origin group
$hostName = az afd endpoint show --profile-name $frontDoorProfile -n $endpointName -g $group -o tsv --query hostName

az afd origin create `
    -g $group `
    --profile-name $frontDoorProfile `
    --origin-group-name $originGroupName `
    --origin-name $originName `
    --host-name $hostName `
    --http-port 80 `
    --https-port 443 `
    --priority 1 `
    --weight 1000 `
    --enabled-state Enabled `
    --enable-private-link true `
    --private-link-resource $privateLinkId `
    --private-link-location $region `
    --private-link-request-message "Connection request from Front Door"

# associate the route
az afd route create `
    -g $group `
    --profile-name $frontDoorProfile `
    --endpoint-name $endpointName `
    --route-name $routeName `
    --origin-group $originGroupName `
    --supported-protocols Http Https `
    --patterns-to-match "/*" `
    --forwarding-protocol MatchRequest `
    --link-to-default-domain Enabled

"Website will be available in a few minutes at http://$hostName"