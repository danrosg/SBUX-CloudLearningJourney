##############################################################################

#  CLI 2.0 Examples - Equivalent exercise to Powershell ALB/AGW exercise     #

##############################################################################

# make sure subscription has services registered that we want...
##  portal / subscriptions / { select } / resource providers 

# Login to Az Account (uses device login)
az login

clear


##############################################################

#                  App Gateway Scenario                      #

##############################################################

#   Create Resource group

az group create --name AGW --location eastus

##############################################################

# Create a new premium storage account for our vm's (name must be unique in AZ)
az storage account create --name agwstoragesakbolke01 --location eastus --resource-group agw --sku premium_lrs

# create standard storage account for boot diagnostics (name must be unique in AZ)
az storage account create --name agwstoragesakoemlke02 --location eastus --resource-group agw --sku standard_lrs

az storage account list --output table 

##########################################################


#########################################################
# Create Network Security Group 
# Rules first
# Then Create NSG + Rules

az network nsg create --name agw-nsg --resource-group AGW --location eastus

# NSG rules
az network nsg rule create --resource-group agw --nsg-name agw-nsg --name web-rule --description "allow http" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 80 --access allow --priority 100 

az network nsg rule create --resource-group agw --nsg-name agw-nsg --name rdp-rule --description "allow rdp" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 3389 --access allow --priority 120 

az network nsg rule list --resource-group agw --nsg-name agw-nsg --output table 

# az network nsg rule delete --resource-group agw --nsg-name agw-nsg --name web-rule 

##########################################################
# create public ip addresses for resources 2 vm's (DNS names - unique)

az network public-ip create --name agw-ip01 --resource-group agw --allocation-method static --dns-name agwvmipuk01 --location eastus 
az network public-ip create --name agw-ip02 --resource-group agw --allocation-method static --dns-name agwvmipus02 --location eastus 

# Get Public IP Address
az network public-ip list --output table 


##########################################################
#  Create Virtual network with Subnets for AGW and VM's
#  (vnet and subnet for AGW) 

# Creates a vnet and 1 subnet in one command 
az network vnet create --name AGWvnet --resource-group agw --address-prefixes 10.0.0.0/16 --location eastus --subnet-name AGWSubnet --subnet-prefix 10.0.0.0/24 

## Let's double check that the Subnet was created before continuing 
az network vnet subnet list --vnet-name AGWvnet --resource-group AGW --output table

## if no subnet, we need to create it using the following, if it's there move on...
# az network vnet subnet create --name AGWSubnet --resource-group agw --vnet-name AGWvnet --address-prefix 10.0.0.0/24

# create new subnet in Vnet for VM's in same VNet 
az network vnet subnet create --name AGWVMs --resource-group agw --vnet-name AGWvnet --address-prefix 10.0.1.0/24

## Let's double check both Subnets before continuing 
az network vnet subnet list --vnet-name AGWvnet --resource-group AGW --output table

########################################################
#
#   Virtual Machines and Availability Sets
#
########################################################

# create new availability set for VM's 
az vm availability-set create --name ASetAGW --resource-group agw --platform-fault-domain-count 2 --platform-update-domain-count 2 --location eastus 

#Create the VM #1 and nic - assign IP created above 
# Change username and password 
az vm create --name agw-vm-01 --resource-group agw --vnet-name AGWvnet --subnet AGWVMs --admin-password ************ --admin-username mycliadmin --availability-set ASetAGW --location eastus --nsg agw-nsg --image Win2016Datacenter --public-ip-address agw-ip01 --size Standard_DS1_v2 

# Looking up image list 
# az vm image list --all --location westus --publisher microsoft --sku 

#Create VM #2 and nic - assign IP from above
# change username and password 
az vm create --name agw-vm-02 --resource-group agw --vnet-name AGWvnet --subnet AGWVMs --admin-password ************ --admin-username mycliadmin --availability-set ASetAGW --location eastus --nsg agw-nsg --image Win2016Datacenter --public-ip-address agw-ip02 --size Standard_DS1_v2 

# docs: https://docs.microsoft.com/en-us/cli/azure/vm#create

az vm list -g agw --output table 

##################################################################

#  Create Application Gateway

##################################################################

### Create the App Gateway, create IP addy for AppGW - set the backend pools to ip addresses
#   ...in one command

az network application-gateway create --name AppGateway01 --resource-group agw --location eastus --sku Standard_Small --capacity 2 --frontend-port 80 --vnet-name AGWvnet --subnet AGWSubnet --routing-rule-type basic --http-settings-cookie-based-affinity Disabled --public-ip-address AppGatewayIP --servers 10.0.1.4 10.0.1.5 

## NOTE: This script will take a long time. May want to do just before break, or put --no-wait on it 
## Can work on RPD step while waiting for AGW install and setup
## NOTE: This example won't work until the VM's have the Web Server Tools installed. 

# RDP to VM's, install web tools, edit homepage to tell us what VM we are on

# copy and paste following line into powershell on our vm's

# Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Also, edit VM's webserver homepage with name of each machine so we can identify in tests
# c:\inetpub\wwwroot\iistart.html
#  ie.  <h1>AGW-CLI-VM-01</h1> vs <h1>AGW-CLI-VM-02</h1>

# Get IPs 
az network public-ip list -g agw --output table 

## RDP connection 
mstsc /v: ${ipaddresses}

start chrome http://{ip-address-agw} or {dns.cloudapp.net}

# start and stop VM's to demonstrate AGW working 

az vm stop -g agw -n agw-vm-02
az vm start -g agw -n agw-vm-01

# Common CLI for linux  
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-manage 


####################

# refresh until you see different machines on the backend
# start and stop different VM's to demonstrate 

#stop 
az vm stop -g agw -n agw-vm-01 
az vm stop -g agw -n agw-vm-02

#start
az vm start -g agw -n agw-vm-01 
az vm start -g agw -n agw-vm-02  

clear



#######################################################################
 
#                 Azure Load Balancer Scenario                        #

#######################################################################

# alb – create etc (edit this all later) 
https://docs.microsoft.com/en-us/cli/azure/network/lb#create
https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-get-started-internet-arm-cli

#Create a group for ALB

az group create --name ALB --location westus2

##############################################################

# Create a new premium storage account for our vm's (name must be unique in AZ)
az storage account create --name albstoragesaenk01 --location westus2 --resource-group alb --sku premium_lrs

# create standard storage account for boot diagnostics (name must be unique in AZ)
az storage account create --name albstoragesaewk02 --location westus2 --resource-group alb --sku standard_lrs

az storage account list -g alb --output table 

##########################################################

# Create Network Security Group 
# Rules first
# Then Create NSG + Rules

az network nsg create --name alb-nsg --location westus2 --resource-group alb 

# NSG rules
az network nsg rule create --resource-group alb --nsg-name alb-nsg --name web-rule --description "allow http" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 80 --access allow --priority 100 
az network nsg rule create --resource-group alb --nsg-name alb-nsg --name rdp-rule --description "allow rdp" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 3389 --access allow --priority 120 
az network nsg rule list --resource-group agw --nsg-name agw-nsg --output table 

###  if you need to delete and redo
# az network nsg rule delete --resource-group blah --nsg-name blah-nsg --name web-rule 


# create new virtual network & subnet 10.0.0.0/24 
az network vnet create --name ALB-VNet --resource-group alb --address-prefixes 10.0.0.0/16 --location westus2 --subnet-name ALB --subnet-prefix 10.0.0.0/24 

## Let's double check that the Subnet was created before continuing 
az network vnet subnet list --vnet-name ALB-VNet --resource-group alb --output table

## if no subnet, we need to create it using the following, if it's there move on...
# az network vnet subnet create --name ALB --resource-group alb --vnet-name ALB-VNet --address-prefix 10.0.0.0/24

# -Name FrontEnd01 -AddressPrefix 10.0.1.0/24
az network vnet subnet create --address-prefix 10.0.1.0/24 --name FrontEnd01 --resource-group alb --vnet-name ALB-VNet

# -Name FrontEnd02 -AddressPrefix 10.0.2.0/24
az network vnet subnet create --address-prefix 10.0.2.0/24 --name FrontEnd02 --resource-group alb --vnet-name ALB-VNet

## repeat above for each subnet you want to add

# add subnet for backend 
#  -Name BackEnd01 -AddressPrefix 10.0.3.0/24
az network vnet subnet create --address-prefix 10.0.3.0/24 --name BackEnd01 --resource-group alb --vnet-name ALB-VNet

# -Name BackEnd02 -AddressPrefix 10.0.4.0/24
az network vnet subnet create --address-prefix 10.0.4.0/24 --name BackEnd02 --resource-group alb --vnet-name ALB-VNet

# Although you create subnets, they currently only exist in the 
# local variable used to retrieve the VNet you create in the step above. 
# To save the changes to Azure, run the following command:

# Remove-AzureRmVirtualNetwork -name blah-vnet -ResourceGroupName blah

##########################################################################

az resource list -g alb --output table 

##########################################################################

# create IP Addresses for new VM's 
az network public-ip create --name alb-ip01 --resource-group alb --allocation-method static --dns-name albvmipveko01 --location westus2 
az network public-ip create --name alb-ip02 --resource-group alb --allocation-method static --dns-name albvmipveko02 --location westus2 

##########################################################################

# Create Availability Set's and Virtual Machines

# create availability set for 2 vm's
az vm availability-set create -n ASetforALB -g alb --platform-fault-domain-count 2 --platform-update-domain-count 2 --location westus2 

# create new subnet in Vnet01 for VM's 
# already have this -   az network vnet subnet create --address-prefix 10.0.1.0/24 --name AGWVMs --resource-group blah --vnet-name VNet01
#  [--network-security-group] #  [--route-table]

#Create the VM #1 and nic - assign IP precreated 
# change username and password 
az vm create --name alb-vm-01 --resource-group alb --vnet-name ALB-VNet --subnet FrontEnd01 --admin-password ************ --admin-username mycliadmin --availability-set ASetforALB --location westus2 --nsg alb-nsg --image Win2016Datacenter --public-ip-address alb-ip01 --size Standard_DS1_v2 

# Looking up image list 
# az vm image list --all --location westus --publisher microsoft --sku 

# docs: https://docs.microsoft.com/en-us/cli/azure/vm#create
           
#Create VM #2 and nic 
# Change username and password
az vm create --name alb-vm-02 --resource-group alb --vnet-name ALB-VNet --subnet FrontEnd01 --admin-password ************ --admin-username mycliadmin --availability-set ASetforALB --location westus2 --nsg alb-nsg --image Win2016Datacenter --public-ip-address alb-ip02 --size Standard_DS1_v2 

az vm list -g alb --output table 


## RDP to machines and setup inet tools and edit home page to say which vm it is
# install webserver tools - run powershell on windows vm - copy & run on VMS
# Install-WindowsFeature -name Web-Server -IncludeManagementTools

# get ip addresses
az network public-ip list --output table 

## RDP connection
mstsc /v: 13.64.190.127
mstsc /v: 40.71.222.141

az resource list -g alb --output table


#############################################################################

#                Azure Load Balancer 

# create IP address for ALB
az network public-ip create --name ALB-ip00 --resource-group alb --allocation-method static --dns-name albipblah --location westus2 

clear

az network lb create --name ALB --resource-group alb  --backend-pool-name ALB-bepool --frontend-ip-name ALB-ip00 --public-ip-address ALB-ip00

# backend pool to availability set issues 
# need to use nic list and loadbalancerbackendaddresspools id 

az network nic list --output table -g alb
az network lb show -n alb -g alb

# add nic's for vm's to lb backend address pools
# IMPORTANT - YOU NEED TO CHANGE THE GUID FOR THE SUBSCRIPTION ID {Your-Subscription-GUID}
# OR RESOURCE ID - IF YOU NAMED THE ALB SOMETHING ELSE. 
# YOU CAN GET THE RESOURCE ID FROM THE PROPERTIES BLADE IN THE PORTAL + the name of backend address pool

az account show
# Id = Subscription ID

az network nic update -g alb --name alb-vm-01VMNic --add ipConfigurations[name=ipconfigalb-vm-01].loadBalancerBackendAddressPools id="/subscriptions/{Your-Subscription-GUID}/resourceGroups/alb/providers/Microsoft.Network/loadBalancers/ALB/backendAddressPools/ALB-bepool"

az network nic update -g alb --name alb-vm-02VMNic --add ipConfigurations[name=ipconfigalb-vm-02].loadBalancerBackendAddressPools id="/subscriptions/{Your-Subscription-GUID}/resourceGroups/alb/providers/Microsoft.Network/loadBalancers/ALB/backendAddressPools/ALB-bepool"

# az network nic update -g ${resource-group} --name ${nic-name} --add ipConfigurations[name=${ip-config}].loadBalancerBackendAddressPools id=${backend-address-pool-id}

# health rule
az network lb probe create -g alb --lb-name ALB -n healthprobe01 --protocol tcp --port 80  

# loadbalancing rule 
az network lb rule create --backend-port 80 --frontend-port 80 --lb-name ALB --name lbrule01 --protocol tcp -g alb --backend-pool-name ALB-bepool --frontend-ip-name ALB-ip00 --probe-name healthprobe01 

# az network lb rule delete --name lbrule01 -g alb --lb-name ALB
# az network lb rule list --lb-name ALB -g alb

# Get IP address for ALB and open in browser
az network public-ip list -g alb --output table


<### Next Steps
add vms/availability set to backend pools on ALB 
RDP and setup machines with 
############################################################>

# To demo failover, stop the vm that's showing in browser, or try different browsers

#ALB VM's - stand alone in subnet in same VNet as AppGW 

#stop 
az vm stop -g alb -n alb-vm-01 
az vm stop -g alb -n alb-vm-02 

#start
az vm start -g alb -n alb-vm-01
az vm start -g alb -n alb-vm-02 



####################### create traffic manager profile #################

Traffic manager:
https://docs.microsoft.com/en-us/cli/azure/network/traffic-manager

#DNS Name needs to be unique in Azure global

az group create -n traffic -l westus 

az network traffic-manager profile create --name trafficmgr --resource-group traffic --routing-method performance --unique-dns-name kolketmgrclidemo 

az network public-ip show -n ALB-ip00 -g alb 

## NOTE: Endpoints need to be edited with your subscription GUID for following to work
#  Edit {Your-Subscription-GUID}

az account show
# id = subscription id 

az network traffic-manager endpoint create --name mytm1 --profile-name trafficmgr --resource-group traffic --type azureEndpoints --target-resource-id "/subscriptions/{Your-Subscription-GUID}/resourceGroups/alb/providers/Microsoft.Network/publicIPAddresses/ALB-ip00" 

# =========================================

az network public-ip show -n AGW-ip01 -g agw

## NOTE: Endpoint needs to be edited with your Subscription GUId for the following to work.
#  Edit {Your-Subscription-GUID}

az network traffic-manager endpoint create --name mytm2 --profile-name trafficmgr --resource-group traffic --type azureEndpoints --target-resource-id "/subscriptions/{Your-Subscription-GUID}/resourceGroups/agw/providers/Microsoft.Network/publicIPAddresses/agw-ip01" 

# Test Traffic MGR

http://kolketmgrclidemo.trafficmanager.net

# Disable Traffic Manager Profile
# Disable-AzureRmTrafficManagerProfile -Name MyTrafficMgrProfile -ResourceGroupName blah  -Force

az network traffic-manager profile update --name trafficmgr --resource-group traffic --status disabled


#ALB VM's - in an availability set   
#stop 
az vm stop -g alb -n alb-vm-01 
az vm stop -g alb -n alb-vm-02 

#App GW VM's - stand alone in subnet in same VNet as AppGW 
#stop 
az vm stop -g agw -n agw-vm-01 
az vm stop -g agw -n agw-vm-02


#ALB VM's - in an availability set  
#start
az vm start -g alb -n alb-vm-01
az vm start -g alb -n alb-vm-02 

#App GW VM's - stand alone in subnet in same VNet as AppGW  
#start
az vm start -g agw -n agw-vm-01 
az vm start -g agw -n agw-vm-02  


#Enable TM
az network traffic-manager profile update --name trafficmgr --resource-group traffic --status enabled


start chrome http://kolketmgrclidemo.trafficmanager.net


#############################################################################

#                         notes

#############################################################################
<#
CLI 2.0 completed these scenarios: 
- resourcegroup
- nsg
- AppGW 
- ALB
- VMs x 4
- Test ALB + AppGW 
- Traffic Manager 
#>

az group list 
# get az account - ID = subscription ID
az account show 

# Note the Subscription ID - we are going to need it later 
# In the examples change {Your-Subscription-GUID} to your SubscriptionID


<### Notes:
execution policy problems - or use portal   
 Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass | Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy AllSigned -Force
 az policy assignment list 
 az policy assignment show --name [--resource-group] [--scope]
#>

#get resource groups
az group list
#get resources
az resource list 
#get resources in specific resource group 
az resource list --output table --resource-group WebApp01


# can also use queries --query JMESPath query string - see jmespath.org for details 

#delete resource group (and all the resources therein) 
# az group delete --name blah --no-wait 

start explorer https://portal.azure.com 
