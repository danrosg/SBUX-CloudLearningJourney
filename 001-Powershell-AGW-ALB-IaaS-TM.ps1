#####################################################################

#         POWERSHELL EXAMPLES 1.1                                   #

#####################################################################

cls

#Login to Az Account
Login-AzureRmAccount

Get-AzureRmADUser

### execution policy problems?
# execution scope policy info
Get-ExecutionPolicy -list
# bypass 
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# current user allsigned-force ### - great for workshop
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy AllSigned -Force


#get resource groups
Get-AzureRmResourceGroup

#get resources
Get-AzureRMResource 

Get-AzureRmResource | select name, kind, location
Get-AzureRmResource | select name, resourcetype, resourcegroupname,location

#get resources in specific resource group 
Get-AzureRmResource | Where-Object { $_.ResourceGroupName -eq "myjenkins"}
Get-AzureRmResource | ? { $_.Name -like "*blah*"}
#Contains Like - CLike - case sensitive plus *
Get-AzureRmResource | Where-Object { $_.ResourceGroupName -CLike "*blah*"} | select name, resourcetype

#delete resource group (and all the resources therein) 
# Remove-AzureRmResourceGroup -Name blah

Start-Process -FilePath "http://portal.azure.com" 

####################################################

#         Application Gateway Scenario
#               create in EastUS 
#          (will create ALB in WestUS)

####################################################

#   Create Resource group for AGW scenario
cls

New-AzureRMResourceGroup -name AGWPS -location eastus

# Remove-AzureRmResourceGroup -name AGWPS -force 

###################################################

# Create a new premium storage account.

# !!!  Storage account names must be unique !!! 
New-AzureRmStorageAccount –StorageAccountName agwpsstoragesan01 -Location eastus -ResourceGroupName AGWPS -SkuName Premium_LRS

# create standard storage account for boot diagnostics 
New-AzureRmStorageAccount –StorageAccountName agwpsstoragesan02 -Location eastus -ResourceGroupName AGWPS -SkuName Standard_LRS

##########################################################


#########################################################
# Create Network Security Group 
# Rules first
# Then Create NSG + Rules

# NSG rules
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 101 `
-SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 80

$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
-SourceAddressPrefix Internet -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange 3389

$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName agwps -Location eastus `
-Name "agwps-nsg" -SecurityRules $rule1,$rule2

$nsg


###########################################################
# create public ip addresses for resources
###########################################################

New-AzureRmPublicIpAddress -Name agwpsvm-ip01 -ResourceGroupName agwps  `
-AllocationMethod Static -DomainNameLabel agwpsvmip01 -Location eastus

New-AzureRmPublicIpAddress -Name agwpsvm-ip02 -ResourceGroupName agwps  `
-AllocationMethod Static -DomainNameLabel agwpsvmip02 -Location eastus

# Create IP for AGW (must be dynamic)
New-AzureRmPublicIpAddress -Name AGWpsPubip -ResourceGroupName agwps  `
-AllocationMethod Dynamic -Location eastus

# Get Public IP Address
Get-AzureRmPublicIpAddress -ResourceGroupName agwps | select name, ipaddress 

# Remove-AzureRmPublicIpAddress -name <name> -ResourceGroupName <g>


##############################################################
## create new vnet for app gateway
## subnet for vms
## add vms to that subnet 

$Subnet = New-AzureRmVirtualNetworkSubnetConfig -Name "AGWPSSubnet" -AddressPrefix 10.0.0.0/24
# this is the key. subnets and vnets... 
$VNet = New-AzureRmvirtualNetwork -Name "AGWPSVnet" -ResourceGroupName "AGWPS" `
-Location "East US" -AddressPrefix 10.0.0.0/16 -Subnet $Subnet 

$VNet = Get-AzureRmvirtualNetwork -Name "AGWPSVnet" -ResourceGroupName "AGWPS"

##############################################################

### create 2 vm's in vnet

# create new availability set 
New-AzureRmAvailabilitySet -ResourceGroupName "AGWPS" -Name "AGWPS-ASet" -Location eastus `
-PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -sku Aligned

# create new subnet in Vnet for VM's 
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName AGWPS -Name AGWPSVnet
#add a subnet to the new vnet variable
Add-AzureRmVirtualNetworkSubnetConfig -Name AGWVMs `
-VirtualNetwork $vnet -AddressPrefix 10.0.1.0/24

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

######## Sidebar ######################################################
### Get a list of all VM images that are available in a region    #####
#######################################################################


#Create the VM1 with 
$AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName AGWPS -name "AGWPS-ASet"
$vnet = Get-AzureRmVirtualNetwork -Name AGWPSVnet -ResourceGroupName AGWPS 
$nsg = Get-AzureRmNetworkSecurityGroup -name agwps-nsg -ResourceGroupName AGWPS
$pip = Get-AzureRmPublicIpAddress -Name agwpsvm-ip01 -ResourceGroupName AGWPS 
# use subnet[1] because [0] has application gateway
$nic = New-AzureRmNetworkInterface -Name agwpsvmNIC-01 -ResourceGroupName AGWPS -Location eastus `
    -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
$cred = Get-Credential
# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName AGWPSvm-01 -VMSize Standard_DS1 -AvailabilitySetID $AvailabilitySet.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName AGWPSvm-01 -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id 
    
# Create the virtual machine with New-AzureRmVM.
New-AzureRmVM -ResourceGroupName AGWPS -Location eastus -VM $vmConfig



############
##VM2 - repeat of steps above
$AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName AGWPS -name "AGWPS-ASet"
$vnet = Get-AzureRmVirtualNetwork -Name AGWPSVnet -ResourceGroupName AGWPS 
$nsg = Get-AzureRmNetworkSecurityGroup -name agwps-nsg -ResourceGroupName AGWPS
$pip = Get-AzureRmPublicIpAddress -Name agwpsvm-ip02 -ResourceGroupName AGWPS 
# use subnet[1] because [0] has application gateway
$nic = New-AzureRmNetworkInterface -Name agwpsvmNIC-02 -ResourceGroupName AGWPS -Location eastus `
    -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
$cred = Get-Credential
# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName AGWPSvm-02 -VMSize Standard_DS1 -AvailabilitySetID $AvailabilitySet.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName AGWPSvm-02 -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id 
    
# Create the virtual machine with New-AzureRmVM.
New-AzureRmVM -ResourceGroupName AGWPS -Location eastus -VM $vmConfig

#RDP to machines, install web tools, and label so we can identify in browser

$pip1 = Get-AzureRmPublicIpAddress -Name agwpsvm-ip01 -ResourceGroupName AGWPS 
$pip2 = Get-AzureRmPublicIpAddress -Name agwpsvm-ip02 -ResourceGroupName AGWPS

# install webserver tools - run powershell on windows vm - copy & run on VMS
# Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Also, edit webserver homepage with name of each machine so we can identify in tests
# c:\inetpub\wwwroot\iistart.html
#  ie.  <h1>AGW-VM-01</h1>

## RDP connection
mstsc /v: $pip1.IpAddress
mstsc /v: $pip2.IpAddress

#####################################################################

# App Gateway Configs
$vnet = Get-AzureRmVirtualNetwork -Name AGWPSVnet -ResourceGroupName AGWPS 
# $Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $Subnet01 -VirtualNetwork $VNet
$Subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name AGWPSSubnet -VirtualNetwork $VNet

$GatewayIPconfig = New-AzureRmApplicationGatewayIPConfiguration -Name "GatewayIp01" -Subnet $Subnet 
$Pool = New-AzureRmApplicationGatewayBackendAddressPool -Name "Pool01" -BackendIPAddresses 10.10.10.1, 10.10.10.2, 10.10.10.3
$PoolSetting = New-AzureRmApplicationGatewayBackendHttpSettings -Name "PoolSetting01"  -Port 80 -Protocol "Http" -CookieBasedAffinity "Disabled"
$FrontEndPort = New-AzureRmApplicationGatewayFrontendPort -Name "FrontEndPort01"  -Port 80

# get a public IP address - must be dynamic - already created above
$PublicIp = get-AzureRmPublicIpAddress -ResourceGroupName "AGWPS" -Name AGWpsPubip
$FrontEndIpConfig = New-AzureRmApplicationGatewayFrontendIPConfig -Name "FrontEndConfig01" -PublicIPAddress $PublicIp
$Listener = New-AzureRmApplicationGatewayHttpListener -Name agwlisten -Protocol "Http" -FrontendIpConfiguration $FrontEndIpConfig -FrontendPort $FrontEndPort
$Rule = New-AzureRmApplicationGatewayRequestRoutingRule -Name "Rule01" -RuleType basic -BackendHttpSettings $PoolSetting -HttpListener $Listener -BackendAddressPool $Pool
$Sku = New-AzureRmApplicationGatewaySku -Name "Standard_Small" -Tier Standard -Capacity 2
$Gateway = New-AzureRmApplicationGateway -Name "AppGatewayPS" -ResourceGroupName "AGWPS" `
-Location "East US" -BackendAddressPools $Pool -BackendHttpSettingsCollection $PoolSetting `
-FrontendIpConfigurations $FrontEndIpConfig  -GatewayIpConfigurations $GatewayIpConfig `
-FrontendPorts $FrontEndPort -HttpListeners $Listener -RequestRoutingRules $Rule -Sku $Sku

# note: long running process / break 
Get-AzureRmApplicationGateway | select name, location, ResourceGroupName


### get IP addresses for backend pools (if using ip addresses)
Get-AzureRmPublicIpAddress | select name, ipaddress


########################################################################
# this works because my vms have static variables
$pip1 = Get-AzureRmPublicIpAddress -Name agwpsvm-ip01 -ResourceGroupName agwps
$pip2 = Get-AzureRmPublicIpAddress -Name agwpsvm-ip02 -ResourceGroupName agwps
$AppGw = Get-AzureRmApplicationGateway -Name "AppGatewayPS" -ResourceGroupName agwps
$Pool = Set-AzureRmApplicationGatewayBackendAddressPool `
-ApplicationGateway $AppGw -Name "Pool01" -BackendIPAddresses $pip1.IpAddress, $pip2.IpAddress
## can use static values for IPs - ie. -BackendIPAddresses "52.168.14.48", "13.82.181.89"

# note: not short setting backend pools 
Set-AzureRmApplicationGateway -ApplicationGateway $AppGw 

$agwip = Get-AzureRmPublicIpAddress -Name AGWpsPubip -ResourceGroupName agwps
$agwip = $agwip.IpAddress 
start-process -filepath http://$agwip

start chrome http://$agwip

# refresh until you see different machines on the backend
# start and stop different VM's to demonstrate 

#App GW VM's - stand alone in subnet in same VNet as AppGW 
stop-azurermvm -ResourceGroupName agwps -name agwpsvm-01 -force
stop-azurermvm -ResourceGroupName agwps -name agwpsvm-02 -force

#App GW VM's - stand alone in subnet in same VNet as AppGW  
start-azurermvm -ResourceGroupName agwps -name agwpsvm-01  
start-azurermvm -ResourceGroupName agwps -name agwpsvm-02 


cls

#######################################################################
 
#                 Azure Load Balancer Scenario                        #
#                               WestUS                                #

#######################################################################



#   Create Resource group for ALBPS scenario
cls

New-AzureRMResourceGroup -name ALBPS -location westus



###################################################

# Create a new premium storage account.

New-AzureRmStorageAccount –StorageAccountName albpsstoragesavn01 -Location westus `
-ResourceGroupName ALBPS -SkuName Premium_LRS

# create standard storage account for boot diagnostics 
New-AzureRmStorageAccount –StorageAccountName albpsstoragesavn02 -Location westus `
-ResourceGroupName ALBPS -SkuName Standard_LRS


##########################################################


#########################################################
# Create Network Security Group 
# Rules first
# Then Create NSG + Rules

# NSG rules
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 101 `
-SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 80

$rule2 = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
-SourceAddressPrefix Internet -SourcePortRange * `
-DestinationAddressPrefix * -DestinationPortRange 3389

$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName albps -Location westus `
-Name "albps-nsg" -SecurityRules $rule1,$rule2

$nsg


##############################################################
# create new virtual network 
New-AzureRmVirtualNetwork -ResourceGroupName ALBPS -Name ALBPS-VNet `
-AddressPrefix 10.0.0.0/16 -Location westus

# Store the virtual network object in a variable:
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName ALBPS -Name ALBPS-VNet

#add a subnet to the new vnet variable

Add-AzureRmVirtualNetworkSubnetConfig -Name FrontEnd01 `
-VirtualNetwork $vnet -AddressPrefix 10.0.1.0/24

Add-AzureRmVirtualNetworkSubnetConfig -Name FrontEnd02 `
-VirtualNetwork $vnet -AddressPrefix 10.0.2.0/24

## repeat above for each subnet you want to add
## don't know what to choose for AddressPrefix if I add more

# add subnet for backend 
Add-AzureRmVirtualNetworkSubnetConfig -Name BackEnd01 `
-VirtualNetwork $vnet -AddressPrefix 10.0.3.0/24

Add-AzureRmVirtualNetworkSubnetConfig -Name BackEnd02 `
-VirtualNetwork $vnet -AddressPrefix 10.0.4.0/24

# Although you create subnets, they currently only exist in the 
# local variable used to retrieve the VNet you create in the step above. 
# To save the changes to Azure, run the following command:

# note: long running process? not really...
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# Remove-AzureRmVirtualNetwork -name <name> -ResourceGroupName <group>

##################################################

Get-AzureRmResource | select name, resourcetype, resourcegroupname, location

##########################################################################

# create ip addresses for vm's

New-AzureRmPublicIpAddress -Name albpsvm-ip01 -ResourceGroupName albps  `
-AllocationMethod Static -DomainNameLabel albpsvmip01 -Location westus

New-AzureRmPublicIpAddress -Name albpsvm-ip02 -ResourceGroupName albps  `
-AllocationMethod Static -DomainNameLabel albpsvmip02 -Location westus

# Create IP for ALB 
New-AzureRmPublicIpAddress -Name ALBpsPubip -ResourceGroupName albps `
-AllocationMethod Static -Location westus -DomainNameLabel albpspubip

# Get Public IP Address
Get-AzureRmPublicIpAddress -ResourceGroupName albps | select name, ipaddress 

Get-AzureRMResource | ? {$_.name -eq "ALBps"} 

##########################################################

# create 2 vm's in availability set using just powershell 

# create availability set 
New-AzureRmAvailabilitySet -ResourceGroupName "albps" -Name "ALBps-ASet" -Location westus `
-PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -Sku Aligned

# VM1 - creating nic then vm 
$AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName albps -name ALBps-ASet 
$vnet = Get-AzureRmVirtualNetwork -Name ALBPS-VNet -ResourceGroupName albps 
$nsg = Get-AzureRmNetworkSecurityGroup -name ALBps-nsg -ResourceGroupName albps
$pip = Get-AzureRmPublicIpAddress -Name albpsvm-ip01 -ResourceGroupName albps 
$nic = New-AzureRmNetworkInterface -Name ALBpsvmNIC-01 -ResourceGroupName albps -Location westus `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration. This configuration includes the settings that are used
#  when deploying the virtual machine such as a virtual machine image, size, and authentication configuration. 
#  When running this step, you are prompted for credentials. The values that you enter are configured 
#  as the user name and password for the virtual machine. 

# Define a credential object
$cred = Get-Credential

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName albpsvm-01 -VMSize Standard_DS1 -AvailabilitySetID $AvailabilitySet.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName albpsvm-01 -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id 
    
# Create the virtual machine with New-AzureRmVM.
# Note: Long running process 
New-AzureRmVM -ResourceGroupName albps -Location westus -VM $vmConfig

##########################################################################
# VM 2 - repeat of above 

$AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName albps -name ALBps-ASet 
$vnet = Get-AzureRmVirtualNetwork -Name ALBPS-VNet -ResourceGroupName albps 
$nsg = Get-AzureRmNetworkSecurityGroup -name ALBps-nsg -ResourceGroupName albps
$pip = Get-AzureRmPublicIpAddress -Name albpsvm-ip02 -ResourceGroupName albps 
$nic = New-AzureRmNetworkInterface -Name ALBpsvmNIC-02 -ResourceGroupName albps -Location westus `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
$cred = Get-Credential
$vmConfig = New-AzureRmVMConfig -VMName albpsvm-02 -VMSize Standard_DS1 -AvailabilitySetID $AvailabilitySet.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName albpsvm-02 -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id 
# Create the virtual machine with New-AzureRmVM.
New-AzureRmVM -ResourceGroupName albps -Location westus -VM $vmConfig

###########################################################################


## RDP connection - rdp to machines and setup webservers
$pip1 = Get-AzureRmPublicIpAddress -Name albpsvm-ip01 -ResourceGroupName albps 
$pip2 = Get-AzureRmPublicIpAddress -Name albpsvm-ip02 -ResourceGroupName albps 

# install webserver tools - run powershell on windows vm - copy & run on VMS
# Install-WindowsFeature -name Web-Server -IncludeManagementTools

## RDP connection
mstsc /v: $pip1.IpAddress
mstsc /v: $pip2.IpAddress

# copy and install webserver tools - run powershell on windows vm
## Install-WindowsFeature -name Web-Server -IncludeManagementTools

##########################################################################

#  Create Azure Load Balancing                                           #

##########################################################################

# get ip etc # set variables
$publicIP = Get-AzureRmPublicIpAddress -Name ALBpsPubip -ResourceGroupName albps 
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-Frontend -PublicIpAddress $publicIP
$beaddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name LB-backend
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName albps -Name ALBPS-VNet

# Create the NAT rules (optional)
# $inboundNATRule1= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP1 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3441 -BackendPort 3389
# $inboundNATRule2= New-AzureRmLoadBalancerInboundNatRuleConfig -Name RDP2 -FrontendIpConfiguration $frontendIP -Protocol TCP -FrontendPort 3442 -BackendPort 3389

# Create a health probe. There are two ways to configure a probe:
# HTTP probe (two methods)
#   $healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -RequestPath 'HealthProbe.aspx' -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
# TCP probe
$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HealthProbe -Protocol Tcp -Port 80 -IntervalInSeconds 15 -ProbeCount 2

# Create a load balancer rule.
$lbrule = New-AzureRmLoadBalancerRuleConfig -Name HTTP -FrontendIpConfiguration $frontendIP -BackendAddressPool  $beAddressPool -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80

# Create the load balancer by using the previously created objects.
$NRPLB = New-AzureRmLoadBalancer -ResourceGroupName albps -Name LoadBalancerPS -Location westus `
-FrontendIpConfiguration $frontendIP -LoadBalancingRule $lbrule -BackendAddressPool $beAddressPool -Probe $healthProbe
# (optional ) -InboundNatRule $inboundNATRule1,$inboundNatRule2 `

$NRPLB

<### Next Steps  ############################################
        add vms/availability set to backend pools on ALB 
        RDP and setup machines with 
############################################################>

# Load the load balancer resource into a variable
$loadbalancer = Get-AzureRmLoadBalancer -Name LoadBalancerPS -ResourceGroupName albps
Get-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-Backend" -LoadBalancer $loadbalancer

# load backendpool config into variable
$backend = Get-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-Backend" -LoadBalancer $loadbalancer

# Load the Network interface- into a variable. The variable name is $nic. 
$nic = get-azurermnetworkinterface -name ALBpsvmNIC-01 -resourcegroupname albps
$nic2 = get-azurermnetworkinterface -name ALBpsvmNIC-02 -resourcegroupname albps

# set to backendpool
$nic.IpConfigurations[0].LoadBalancerBackendAddressPools=$backend
$nic2.IpConfigurations[0].LoadBalancerBackendAddressPools=$backend

#Save the network interface object.
Set-AzureRmNetworkInterface -NetworkInterface $nic
Set-AzureRmNetworkInterface -NetworkInterface $nic2


########################################
# Note: Why I am not creating NICs? Instead I am using VM's in an availability set and I'll use their NIC's later
#################################################################################################################


Get-AzureRmResource | select name, resourcetype, resourcegroupname, location

Get-AzureRmPublicIpAddress | select name, ipaddress

# get IP address and open in a browser

$albip = Get-AzureRmPublicIpAddress -Name ALBpsPubip -ResourceGroupName albps
$albip = $albip.IpAddress 
Start-Process -Filepath http://$albip

start chrome http://$albip

# To demo failover, stop the vm that's showing in browser, or try different browsers

#Alb VM's -  
stop-azurermvm -ResourceGroupName albps -name albpsvm-01 -force
stop-azurermvm -ResourceGroupName albps -name albpsvm-02 -force

#Alb VM's -  
start-azurermvm -ResourceGroupName albps -name albpsvm-01  
start-azurermvm -ResourceGroupName albps -name albpsvm-02 




####################### create traffic manager profile #################
cls

New-AzureRMResourceGroup -name TrafficPS -location westus

########################################################

get-azurermpublicipaddress | select name, ipaddress

# Relative DNS Name needs to be unique in Azure global
$profile = New-AzureRmTrafficManagerProfile -Name MyTrafficMgrProfile `
-ResourceGroupName TrafficPS -TrafficRoutingMethod Weighted `
-RelativeDnsName kolketrafficpsdemo -Ttl 30 -MonitorProtocol `
HTTP -MonitorPort 80 -MonitorPath "/"

$ip1 = Get-AzureRmPublicIpAddress -Name ALBpsPubip -ResourceGroupName albps
New-AzureRmTrafficManagerEndpoint -Name ALBPS -ProfileName MyTrafficMgrProfile `
 -ResourceGroupName trafficps -Type AzureEndpoints -TargetResourceId $ip1.Id `
 -EndpointStatus Enabled

$ip2 = Get-AzureRmPublicIpAddress -Name AGWpsPubip -ResourceGroupName agwps
New-AzureRmTrafficManagerEndpoint -Name AGWPS -ProfileName MyTrafficMgrProfile `
 -ResourceGroupName trafficps -Type AzureEndpoints -TargetResourceId $ip2.Id `
 -EndpointStatus Enabled

#make sure you change subdomain name to match TM profile name
start-process http://kolketrafficpsdemo.trafficmanager.net

# More about trafficmgr and powershell
# https://docs.microsoft.com/en-us/azure/traffic-manager/traffic-manager-powershell-arm#create-a-traffic-manager-profile
# 

Login-AzureRmAccount

# Disable Traffic Manager Profile
Disable-AzureRmTrafficManagerProfile -Name MyTrafficMgrProfile -ResourceGroupName trafficps  -Force

#ALB VM's - in an availability set   


#App GW VM's - stand alone in subnet in same VNet as AppGW 


Get-AzureRmVM -Status | Select ResourceGroupName, Name, PowerState


#App GW VM's -
stop-azurermvm -ResourceGroupName agwps -name agwpsvm-01 -force
stop-azurermvm -ResourceGroupName agwps -name agwpsvm-02 -force

#App GW VM's -
start-azurermvm -ResourceGroupName agwps -name agwpsvm-01  
start-azurermvm -ResourceGroupName agwps -name agwpsvm-02 

#ALB VM's - 
stop-azurermvm -ResourceGroupName albps -name albpsvm-01 -force
stop-azurermvm -ResourceGroupName albps -name albpsvm-02 -force

#ALB VM's -  
start-azurermvm -ResourceGroupName albps -name albpsvm-01  
start-azurermvm -ResourceGroupName albps -name albpsvm-02 


Get-AzureRmVM -Status | Select ResourceGroupName, Name, PowerState

#Enable TM
Enable-AzureRmTrafficManagerProfile -Name MyTrafficMgrProfile -ResourceGroupName trafficps

start-process http://kolketrafficpsdemo.trafficmanager.net




#############################################################################

#                         notes

#############################################################################
<#
powershell completed these scenarios: 
- resourcegroup
- nsg
- AppGW 
- ALB
- VMs x 4
- Test ALB + AppGW 
- Traffic Manager 
#> 

# where from here? ideas...
# - add vm / arm template, start with portal
# - monitoring 
# - security
# - view resources in portal 
