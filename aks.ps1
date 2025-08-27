. .\vars.ps1

$vnet = "vnet"

# create resource group
az group create -n $group -l $region

# create the vnet and subnets for AKS
az network vnet create -n $vnet -g $group --address-prefixes 10.0.0.0/16

$subnetId = az network vnet subnet create `
    -n aks `
    --vnet-name $vnet `
    -g $group `
    --address-prefixes 10.0.0.0/24 `
    -o tsv --query id

# create the AKS cluster
az aks create -n $cluster -g $group `
    -c 1 `
    -k 1.33 `
    --enable-app-routing `
    --app-routing-default-nginx-controller Internal `
    --vnet-subnet-id $subnetId `
    --service-cidr 10.1.0.0/24 `
    --network-plugin azure `
    --dns-service-ip 10.1.0.3

# authenticate to the cluster
az aks get-credentials -n $cluster -g $group --overwrite-existing