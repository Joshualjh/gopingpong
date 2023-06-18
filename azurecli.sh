# Variable
$aksrg="rg-krc-dev-aks01"
$aksvnet01="vnet-krc-dev-aks01"
$akssnet01="snet-krc-dev-aks01"
$akscluster="aks-krc-dev-app01"
$aksnodepool="nokrcdaks01"
$aksnoderg="rg-krc-dev-node01"
$vmsnet01="snet-krc-dev-vm01"
$vmnsg01="nsg-krc-dev-vm01"
$vmpip01="pip01-krc-dev-jenkins01"
$vmnic01="nic01-krc-dev-jenkins01"
$vmosdisk="osdisk-krc-dev-jenkis01"
$vmname="vmkrcdevjenkins"
$vmusername="azureuser"
$vmpassword="Password1234"

#use azure cli  
az login
az account set --subscription "Subscription ID"

# config resource group
az group list --output table

# create resource group, virtual network, subnet
az group create -n $aksrg --location koreacentral
az network vnet create -g $aksrg -n $aksvnet01 --subnet-name $akssnet01 --address-prefixes "10.0.0.0/16" --subnet-prefixes "10.0.0.0/24" 
az network vnet subnet create -g $aksrg --vnet-name $aksvnet01 -n $vmsnet01 --address-prefixes "10.0.1.0/24"

# nsg create for vm 
az network nsg create -g $aksrg -n $vmnsg01
az network nsg rule create -g $aksrg --nsg-name $vmnsg01 -n nsgsr-vm-ssh --destination-port-ranges 22 --access Allow --priority 100 --description "ssh" 
az network nsg rule create -g $aksrg --nsg-name $vmnsg01 -n nsgsr-vm-http --destination-port-ranges 80 --access Allow --priority 200 --description "http" 
az network nsg rule create -g $aksrg --nsg-name $vmnsg01 -n nsgsr-vm-jenkins --destination-port-ranges 8080 --access Allow --priority 300 --description "jenkins" 
az network nsg rule create -g $aksrg --nsg-name $vmnsg01 -n nsgsr-vm-go --destination-port-ranges 9000 --access Allow --priority 400 --description "when i make my project, i use this port for golang" 
# connect nsg to subnet
az network vnet subnet update -g $aksrg -n $vmsnet01 --vnet-name $aksvnet01 --network-security-group $vmnsg01

# create vm with pip
az network public-ip create --name $vmpip01  -g $aksrg --sku Standard
az network nic create -g $aksrg -n $vmnic01 --vnet-name $aksvnet01 --subnet $vmsnet01 --private-ip-address 10.0.1.4 --location koreacentral --public-ip-address $vmpip01
az vm create -g $aksrg --name $vmname --image UbuntuLTS --admin-username $vmusername --admin-password $vmpassword --size Standard_D2S_v5 --os-disk-name $vmosdisk --os-disk-size-gb 30 --os-disk-caching ReadWrite --storage-sku StandardSSD_LRS --nics $vmnic01

# Generate aks using azurecni
az aks create --resource-group $aksrg --name $akscluster --network-plugin azure --nodepool-name $aksnodepool --node-vm-size standard_d2s_v5 --node-count 1 --vnet-subnet-id $(az network vnet subnet list --resource-group $aksrg --vnet-name $aksvnet01 --query "[0].id" --output tsv) --node-resource-group $aksnoderg --docker-bridge-address 172.17.0.1/16 --dns-service-ip 10.2.0.10 --service-cidr 10.2.0.0/24 --generate-ssh-keys

# Generate acr
az acr create --name k8scicdacrtest01 -g $aksrg --sku Basic --admin-enabled true

# connect aks to acr (role)
az aks update -n $akscluster -g $aksrg --attach-acr $(az acr list --resource-group $aksrg --query "[0].id" --output tsv)

# connect cluster
az aks get-credentials --resource-group $aksrg --name $akscluster

# config connection
kubectl get nodes

# create rbac for jenkins
az ad sp create-for-rbac
$ACR_ID=$(az acr show --resource-group $aksrg --name k8scicdacrtest01 --query "id" --output tsv)
az role assignment create --assignee 8d1bd7eb-0bd5-4fcd-992c-95bbdd0d7b95 --role Contributor --scope $ACR_ID