##############################################################################

#  CLI 2.0 ALB/AGW/TM exercise                                               #

##############################################################################
# 
# Welcome to this CLI 2.0 Lab
# We will build the following scenario in this lab:
# You will create 2 virtual hosting solutions on the East and West coasts with 
# a solution to manage traffic between the two, and failover. 
#   Traffic Manager --> East & West DR 
#   EAST --> Resource Group - AGW + VNETs/Subnets - 2 VM's in Availability Set
#   WEST --> Resource Group - ALB + VNETs/Subnets - 2 VM's in Availability Set
# Before we begin:
# We need to make sure subscription has services registered that we want...
# Navigate to: 
# - portal / subscriptions / { select } / resource providers 
# Register the following: Compute, Network, Storage, DocumentDB, Web
# Note: If you have other labs you want to try, you may need to add those
# resource providers using this same process.
#
# 
# The following examples are using CLI 2.0
# Documentation for CLI 2.0 is best found here:
# https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest
# see bottom menu item: reference 
#
##############################################################################

# Login to Az Account (uses device login)
az login

# The above command will direct you to aka.ms/devicelogin with a code
#   to authenticate to your azure account

# clear the screen
clear


##############################################################################

#                  EAST US App Gateway Scenario              #

##############################################################################
# This Scenario builds the following
#   EAST --> Resource Group - AGW + VNETs/Subnets - 2 VM's in Availability Set

##############################################################################
# Start with a Resource Group
#   Create Resource group

az group create --name AGW --location eastus

##############################################################################
#
# Storage accounts - 
# we use storage accounts for storing disk image and boot diagnostics/logs

# Create a new premium storage account for our vm's (name must be unique in AZ)
az storage account create --name agw2018storekolke01 --location eastus --resource-group agw --sku premium_lrs

# create standard storage account for boot diagnostics (name must be unique in AZ)
az storage account create --name agw2018storekolke02 --location eastus --resource-group agw --sku standard_lrs

az storage account list --output table 

##############################################################################

#           Network Security Group (NSG's)

##############################################################################
# Create Network Security Group (NSG's)

az network nsg create --name agw-nsg --resource-group AGW --location eastus

# NSG rules - define traffic in/out, allow/deny
az network nsg rule create --resource-group agw --nsg-name agw-nsg --name web-rule --description "allow http" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 80 --access allow --priority 100 

az network nsg rule create --resource-group agw --nsg-name agw-nsg --name rdp-rule --description "allow rdp" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 3389 --access allow --priority 120 

az network nsg rule list --resource-group agw --nsg-name agw-nsg --output table 

# If you need to delete an NSG rule, here is a sample command 
# az network nsg rule delete --resource-group agw --nsg-name agw-nsg --name web-rule 

##############################################################################
#
#       IP Addresses for Resources 
#
# create public ip addresses for resources, 2 vm's (DNS names must be unique)

az network public-ip create --name agw-ip01 --resource-group agw --allocation-method static --dns-name agwdkolke01 --location eastus 
az network public-ip create --name agw-ip02 --resource-group agw --allocation-method static --dns-name agwdkolke02 --location eastus 

# Note: we are using static for this lab, just so we have a consistent IP address to go to for testing.
# More common use case is to use dynamic IP addresses for VM's.

# Get Public IP Address
az network public-ip list --output table 

##############################################################################
#
#       Virtual Network  (VNet) 
#
#  Create Virtual network with Subnets for AGW and VM's
#  Note: App Gateway needs to be in a seperate Subnet from VMs.
# 
#  This command both creates a vnet and one subnet in one command
az network vnet create --name AGWvnet --resource-group agw --address-prefixes 10.0.0.0/16 --location eastus --subnet-name AGWSubnet --subnet-prefix 10.0.0.0/24 

## Let's double check that the Subnet was created before continuing 
az network vnet subnet list --vnet-name AGWvnet --resource-group AGW --output table

## Just in case, if there is no subnet, we will need to create it using the following, if it's there move on...
# az network vnet subnet create --name AGWSubnet --resource-group agw --vnet-name AGWvnet --address-prefix 10.0.0.0/24

# create new second subnet in Vnet for VM's in same VNet 
az network vnet subnet create --name AGWVMs --resource-group agw --vnet-name AGWvnet --address-prefix 10.0.1.0/24

## Let's double check both Subnets before continuing 
az network vnet subnet list --vnet-name AGWvnet --resource-group AGW --output table

##############################################################################
#
#   Virtual Machines and Availability Set
#
##############################################################################

# create new availability set for VM's defining default + update domains
az vm availability-set create --name ASetAGW --resource-group agw --platform-fault-domain-count 2 --platform-update-domain-count 2 --location eastus 

# Create the VM #1 and nic - assign IP created above 
# Note: Change username and password for the VM you are about to create with this next line
az vm create --name agw-vm-01 --resource-group agw --vnet-name AGWvnet --subnet AGWVMs --admin-password ************** --admin-username mycliadmin --availability-set ASetAGW --location eastus --nsg agw-nsg --image Win2016Datacenter --public-ip-address agw-ip01 --size Standard_DS1_v2 

# What types of VM's are these? We are using "managed disks". 
# More about managing VM's with CLI
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-manage
# docs: https://docs.microsoft.com/en-us/cli/azure/vm#create
# az vm list-sizes --location eastus --output table

# Create a second VM and nic and assign IP from above
# Remember to change the username and password 
az vm create --name agw-vm-02 --resource-group agw --vnet-name AGWvnet --subnet AGWVMs --admin-password ************** --admin-username mycliadmin --availability-set ASetAGW --location eastus --nsg agw-nsg --image Win2016Datacenter --public-ip-address agw-ip02 --size Standard_DS1_v2 

##############################################################################
# Next step: RDP to Machines and turn them into simple Web Servers 
# Edit default web page so we can identify machines in tests

# copy and paste following line into powershell on our vm's
# Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Also, edit VM's webserver homepage with name of each machine so we can identify in tests
# c:\inetpub\wwwroot\iistart.html
#  ie.  <h1>AGW-CLI-VM-01</h1> vs <h1>AGW-CLI-VM-02</h1>

# Get IPs for VM's to RDP to 
az network public-ip list -g agw --output tsv

## RDP connection (mstsc works on windows)
mstsc /v: ${ipaddresses}

az vm list -g agw --output table 

##############################################################################

#  Create Application Gateway 

##############################################################################
# NOTE: This example won't work until the VM's have the Web Server Tools installed in previous step.
# The following command:
# Creates the App Gateway, 
# Creates an IP addy for AppGW,
# Sets the backend pools to ip addresses in subnet with VM's

az network application-gateway create --name AppGateway01 --resource-group agw --location eastus --sku Standard_Small  --capacity 2 --frontend-port 80 --vnet-name AGWvnet --subnet   AGWSubnet --routing-rule-type basic --http-settings-cookie-based-affinity Disabled --public-ip-address AppGatewayIP --servers 10.0.1.4 10.0.1.5 
## NOTE: This script will take a long time.

start chrome http://{ip-address-agw} or {http://appgwdnsname.cloudapp.net}

# start and stop VM's to demonstrate AGW working 

az vm stop -g agw -n agw-vm-02
az vm start -g agw -n agw-vm-01

# Common CLI for linux  
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-manage 
#
##############################################################################
# 
# Next: refresh until you see different machines on the backend
# start and stop different VM's to demonstrate 

#stop 
az vm stop -g agw -n agw-vm-01 
az vm stop -g agw -n agw-vm-02

#start
az vm start -g agw -n agw-vm-01 
az vm start -g agw -n agw-vm-02  

clear

# This completes the App Gateway Scenario 

##############################################################################
 
#                 Azure Load Balancer Scenario                               #

##############################################################################
# This Scenario builds the following
#   WEST --> Resource Group - ALB + VNETs/Subnets - 2 VM's in Availability Set
# 
# Docs about ALB and CLI
# https://docs.microsoft.com/en-us/cli/azure/network/lb#create
# https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-get-started-internet-arm-cli
#
##############################################################################
# Start with a New Resource Group
# Create a group for ALB

az group create --name ALB --location westus2

##############################################################################

# Create a new premium storage account for our vm's (name must be unique in AZ)
az storage account create --name alb2018storekolke01 --location westus2 --resource-group alb --sku premium_lrs

# create standard storage account for boot diagnostics (name must be unique in AZ)
az storage account create --name alb2018storekolke02 --location westus2 --resource-group alb --sku standard_lrs

az storage account list -g alb --output table 

##############################################################################
# Network Security Group (NSG's)
#
# First Create Network Security Group 
# Then Create NSG Rules for traffic allow/deny

az network nsg create --name alb-nsg --location westus2 --resource-group alb 

# NSG rules
az network nsg rule create --resource-group alb --nsg-name alb-nsg --name web-rule --description "allow http" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 80 --access allow --priority 100 

az network nsg rule create --resource-group alb --nsg-name alb-nsg --name rdp-rule --description "allow rdp" --direction inbound --protocol tcp --source-port-range "*" --source-address-prefix internet --destination-port-range 3389 --access allow --priority 120 

# List NSG Rules
az network nsg rule list --resource-group agw --nsg-name agw-nsg --output table 

###  if you need to delete and redo
# az network nsg rule delete --resource-group blah --nsg-name blah-nsg --name web-rule 

##############################################################################
# 
#                Virtual Networks and Subnets 
#
# We will create a Vnet + 1 Subnet:
# 1 Subnet for the VM's
# Note: ALB, unlike AGW - does not need to be in a Subnet 
#
# create new virtual network & subnet 10.0.1.0/24 
az network vnet create --name ALB-VNet --resource-group alb --address-prefixes 10.0.0.0/16 --location westus2 --subnet-name ALB-VNet --subnet-prefix 10.0.1.0/24 

## Let's double check that the Subnet was created before continuing 
az network vnet subnet list --vnet-name ALB-VNet --resource-group alb --output table


## if no subnet, we need to create it using the following, if it's there move on...
# -Name FrontEnd01 -AddressPrefix 10.0.1.0/24
# az network vnet subnet create --address-prefix 10.0.1.0/24 --name FrontEnd01 --resource-group alb --vnet-name ALB-VNet

# Optional Add more FrontEnd / Backend Subnets
# ie. --name FrontEnd02 --AddressPrefix 10.0.2.0/24
# az network vnet subnet create --address-prefix 10.0.2.0/24 --name FrontEnd02 --resource-group alb --vnet-name ALB-VNet
# add subnet for backend -Name BackEnd01 -AddressPrefix 10.0.3.0/24
# az network vnet subnet create --address-prefix 10.0.3.0/24 --name BackEnd01 --resource-group alb --vnet-name ALB-VNet
# -Name BackEnd02 -AddressPrefix 10.0.4.0/24
# az network vnet subnet create --address-prefix 10.0.4.0/24 --name BackEnd02 --resource-group alb --vnet-name ALB-VNet
### note: We don't need to put ALB in a Subnet, ie: az network vnet create --name ALB-VNet --resource-group alb --address-prefixes 10.0.0.0/16 --location westus2 --subnet-name ALB --subnet-prefix 10.0.0.0/24 

# Get list of subnets in this VNet
az network vnet subnet list --vnet-name ALB-VNet --resource-group alb --output table


##############################################################################

az resource list -g alb --output table 

##############################################################################
# Virtual IP Addresses 
#
# Create 2 New IP Addresses for 2 new VM's (DNS names must be unique)
az network public-ip create --name alb-ip01 --resource-group alb --allocation-method static --dns-name albkolke01 --location westus2 
az network public-ip create --name alb-ip02 --resource-group alb --allocation-method static --dns-name albkolke02 --location westus2 

# Note: we are using static for this lab, just so we have a consistent IP address to go to for testing.
# More common use case is to use dynamic IP addresses for VM's.

##############################################################################

# Create Availability Set's and Virtual Machines

# create availability set for 2 vm's
az vm availability-set create -n ASetforALB -g alb --platform-fault-domain-count 2 --platform-update-domain-count 2 --location westus2 

# Create VM #1 and nic - assign IP we already created  
# remember to change the username and password 
az vm create --name alb-vm-01 --resource-group alb --vnet-name ALB-VNet --subnet FrontEnd01 --admin-password ************* --admin-username mycliadmin --availability-set ASetforALB --location westus2 --nsg alb-nsg --public-ip-address alb-ip01 --image Win2016Datacenter --size Standard_F2S_v2 
           
# Create VM #2 and nic - assign IP#2 we already created
# remember to change username and password
az vm create --name alb-vm-02 --resource-group alb --vnet-name ALB-VNet --subnet FrontEnd01 --admin-password ************* --admin-username mycliadmin --availability-set ASetforALB --location westus2 --nsg alb-nsg --public-ip-address alb-ip02 --image Win2016Datacenter --size Standard_F2S_v2 

az vm list -g alb --output table 

## RDP to machines and setup inet tools and edit home page to say which vm it is
# install webserver tools - run powershell on windows vm - copy & run on VMS
# Install-WindowsFeature -name Web-Server -IncludeManagementTools

# get ip addresses
az network public-ip list --output table 

## RDP connection
mstsc /v: {ip address}

az resource list -g alb --output table

##############################################################################

#                Azure Load Balancer 

# Create a new IP address for our ALB
az network public-ip create --name ALB-ip00 --resource-group alb --allocation-method static --dns-name albkolkeip --location westus2 

# create the Load Balancer, add ip address and create backend pools 
az network lb create --name ALB --resource-group alb  --backend-pool-name ALB-bepool --frontend-ip-name ALB-ip00 --public-ip-address ALB-ip00

az network nic list -g alb --output table
az network lb show -n alb -g alb

# to setup backend pools, and map to VM's we need to use the NIC's for the VM's

# IMPORTANT in the following - YOU NEED TO CHANGE THE GUID FOR THE SUBSCRIPTION ID {Your-Subscription-GUID}
# Also RESOURCE ID, IF YOU NAMED THE ALB SOMETHING ELSE. 
# YOU CAN GET THE RESOURCE ID FROM THE PROPERTIES BLADE IN THE PORTAL + the name of backend address pool

az account show
# Id = Subscription ID

az network nic update -g alb --name alb-vm-01VMNic --add ipConfigurations[name=ipconfigalb-vm-01].loadBalancerBackendAddressPools id="/subscriptions/{Your-Subscription-GUID}/resourceGroups/alb/providers/Microsoft.Network/loadBalancers/ALB/backendAddressPools/ALB-bepool"

az network nic update -g alb --name alb-vm-02VMNic --add ipConfigurations[name=ipconfigalb-vm-02].loadBalancerBackendAddressPools id="/subscriptions/{Your-Subscription-GUID}/resourceGroups/alb/providers/Microsoft.Network/loadBalancers/ALB/backendAddressPools/ALB-bepool"

# az network nic update -g ${resource-group} --name ${nic-name} --add ipConfigurations[name=${ip-config}].loadBalancerBackendAddressPools id=${backend-address-pool-id}

# Create ALB health rule 
az network lb probe create -g alb --lb-name ALB -n healthprobe01 --protocol tcp --port 80  

# Create ALB loadbalancing rule 
az network lb rule create --backend-port 80 --frontend-port 80 --lb-name ALB --name lbrule01 --protocol tcp -g alb --backend-pool-name ALB-bepool --frontend-ip-name ALB-ip00 --probe-name healthprobe01 

# List LB Rule List
az network lb rule list --lb-name ALB -g alb

# If you need to delete 
# az network lb rule delete --name lbrule01 -g alb --lb-name ALB

# Get IP address for ALB and open in browser
az network public-ip list -g alb --output tsv


##############################################################################
# To demo failover, stop the vm that's showing in browser, or try different browsers

#stop 
az vm stop -g alb -n alb-vm-01 
az vm stop -g alb -n alb-vm-02 

#start
az vm start -g alb -n alb-vm-01
az vm start -g alb -n alb-vm-02 

# end Azure Load Balancer scenario

##############################################################################
#
#       Traffic manager   
#
# Traffic manager is DNS level traffic routing, ideal for disaster recovery
# and load balancing between multiple data centers

# Traffic manager CLI Docs
# https://docs.microsoft.com/en-us/cli/azure/network/traffic-manager

# Create New Resource Group for Traffic Manager
az group create -n traffic -l westus 

# Create Traffic Manager Profile (DNS name must be unique )
az network traffic-manager profile create --name trafficmgr --resource-group traffic --routing-method performance --unique-dns-name kolketmclidemo 

az network public-ip show -n ALB-ip00 -g alb 

## NOTE: Endpoints need to be edited with your subscription GUID for following to work
#  Edit {Your-Subscription-GUID} and resource id (mine is ALB-ip00)

az account show
# id = subscription id 

# --
az network traffic-manager endpoint create --name mytm1 --profile-name trafficmgr --resource-group traffic --type azureEndpoints --target-resource-id "/subscriptions/{Your-Subscription-GUID}/resourceGroups/alb/providers/Microsoft.Network/publicIPAddresses/ALB-ip00" 

# ##############################################################################

az network public-ip show -n AGW-ip01 -g agw

## NOTE: Endpoint needs to be edited with your Subscription GUId for the following to work.
#  Edit {Your-Subscription-GUID} and resource id (mine is AppGatewayIP)

az network traffic-manager endpoint create --name mytm2 --profile-name trafficmgr --resource-group traffic --type azureEndpoints --target-resource-id "/subscriptions/{Your-Subscription-GUID}/resourceGroups/agw/providers/Microsoft.Network/publicIPAddresses/AppGatewayIP" 

# Test Traffic MGR

start chrome http://kolketmclidemo.trafficmanager.net

# Disable Traffic Manager Profile
# az network traffic-manager profile update --name trafficmgr --resource-group traffic --status disabled
# Enable Traffic Manager Profile
# az network traffic-manager profile update --name trafficmgr --resource-group traffic --status enabled

# Test failover by stopping VM's to see traffic fail and reroute

#ALB VM's - in an availability set   
az vm stop -g alb -n alb-vm-01 
az vm stop -g alb -n alb-vm-02 

#App GW VM's - stand alone in subnet in same VNet as AppGW 
az vm stop -g agw -n agw-vm-01 
az vm stop -g agw -n agw-vm-02


#ALB VM's - in an availability set  
az vm start -g alb -n alb-vm-01
az vm start -g alb -n alb-vm-02 

#App GW VM's - stand alone in subnet in same VNet as AppGW  
az vm start -g agw -n agw-vm-01 
az vm start -g agw -n agw-vm-02  


start chrome http://kolketmgrclidemo.trafficmanager.net


##############################################################################

#                         notes

##############################################################################
# With CLI 2.0 we have completed these scenarios: 
#
# resourcegroup's x3
# nsg x2 
# vnets + subnets
# availability sets
# AppGW 
# ALB
# VMs x 4
# Test ALB + AppGW 
# Traffic Manager 
#

az group list 
# get az account - ID = subscription ID
az account show 

# get resource groups
az group list
#get resources
az resource list 
#get resources in specific resource group 
az resource list --output table --resource-group WebApp01

start explorer https://portal.azure.com 
