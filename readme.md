# AKS Managed App Routing with Private Link Service

This sample deployment creates an AKS cluster using managed the [application routing add-on (nginx)](https://learn.microsoft.com/en-us/azure/aks/app-routing). It deploys a sample application that exposes a private load balancer and uses the private link service to allow public connectivity from Azure Front Door.

## Components
- AKS cluster
    - Private load balancer
    - Private link service
- Azure Front Door

## Quickstart

Modify any resource names in the [vars.ps1](./vars.ps1) file as needed, such as region and resource group. 

### Create the AKS Cluster

Invoke [aks.ps1](./aks.ps1) to create the AKS cluster and authenticate `kubectl`. The application routing add-on will create an `Internal` nginx instance configured to expose an IP on the associated subnet (additional options exist on the `NginxIngressController` used for this demo to control the location of the subnet and IP address).

```powershell
# run the aks deployment
.\aks.ps1
```

Once the cluster has been created, deploy the internal `NginxIngressController` and a sample "dockerdemo" workload.

```powershell
# deploy the internal nginx configuration controller
kubectl apply -f .\nginxcontroller.yaml

# deploy the workload (deployment and service)
kubectl apply -f .\workload.yaml -f .\ingress.yaml
```

When [nginxcontroller.yaml](./nginxcontroller.yaml) is deployed, the `service.beta.kubernetes.io/azure-pls-create: "true"` annotation will automatically create the private link service associated with the internal load balancer. The annotation `service.beta.kubernetes.io/azure-pls-name` will name the instance "akspls".

### Create Azure Front Door

When the cluster and the workload are deployed, you should see a private link service created. You can list the PLS instances using the command below. The name of the PLS instance should be the name of the `service.beta.kubernetes.io/azure-pls-name` annotation in the `NginxIngressController` resource.

```powershell
# view the PLS instances
az network private-link-service list -o table
```

Once this is verified, run the setup for Azure Front Door to configure the policy, route, and configure the origin to use the PLS instance. 

```powershell
# run the AFD deployment
.\afd.ps1
```

## Handy Commands

```powershell
# get the list or private link services
az network private-link-service list -o table

# get the ID
az network private-link-service show -g mc_rg-aks-ingress2_ingresscluster_eastus2 -n akspls -o tsv --query id
```

## Links
- [Connect Azure Front Door Premium to an App Service (Web App or Function App) origin with Private Link](https://learn.microsoft.com/en-us/azure/frontdoor/standard-premium/how-to-enable-private-link-web-app?source=recommendations&pivots=front-door-cli)
- [Secure your Origin with Private Link in Azure Front Door Premium](https://learn.microsoft.com/en-us/azure/frontdoor/private-link)
- [Azure LoadBalancer](https://cloud-provider-azure.sigs.k8s.io/topics/loadbalancer/#loadbalancer-annotations)
- [Origins and origin groups in Azure Front Door](https://learn.microsoft.com/en-us/azure/frontdoor/origin?pivots=front-door-standard-premium)