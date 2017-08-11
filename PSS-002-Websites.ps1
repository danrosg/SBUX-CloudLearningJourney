cls

Login-AzureRmAccount

New-AzureRmResourceGroup -name mywebsites01 -Location westus

################# create NSG #################
# Create Network Security Group 
# Rules first
# Then Create NSG + Rules

# NSG rules
$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" `
-Access Allow -Protocol Tcp -Direction Inbound -Priority 101 `
-SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
-DestinationPortRange 80

$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName mywebsites -Location westus `
-Name "website-nsg" -SecurityRules $rule1

$nsg

################# create vnet ################
# create new virtual network 
# see example - need subnet and gateway
# also requires a manual step from the portal, so not sure it's worth it. 
# might as well just use the portal 

New-AzureRmVirtualNetwork -ResourceGroupName mywebsites -Name mywebsites-VNet `
-AddressPrefix 10.0.0.0/16 -Location westus

# Store the virtual network object in a variable:
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName mywebsites -Name mywebsites-VNet

#add a subnet to the new vnet variable
Add-AzureRmVirtualNetworkSubnetConfig -Name FrontEnd01 `
-VirtualNetwork $vnet -AddressPrefix 10.0.1.0/24
## repeat above for each subnet you want to add 

# add subnet for backend 
Add-AzureRmVirtualNetworkSubnetConfig -Name BackEnd02 `
-VirtualNetwork $vnet -AddressPrefix 10.0.2.0/24

# Although you create subnets, they currently only exist in the 
# local variable used to retrieve the VNet you create in the step above. 
# To save the changes to Azure, run the following command:

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
# Remove-AzureRmVirtualNetwork -name mywebsites-vnet -ResourceGroupName mywebsites

##############################################
#  create app service plan
##############################################

New-AzureRmAppServicePlan -Name website01 -Location westus -ResourceGroupName mywebsites01 `
-Tier Premium -WorkerSize Medium -NumberofWorkers 1

#Tier: the desired pricing tier (Default is Free, other options are Shared, Basic, Standard, and Premium.)

<# Notes: - app service plan - app service environment 
New-AzureRmAppServicePlan -Name website01 -Location westus `
-ResourceGroupName mywebsites -AseName constosoASE -AseResourceGroupName contosoASERG `
-Tier Premium -WorkerSize Large -NumberofWorkers 10
#>

#list service plans under your account
Get-AzureRmAppServicePlan

# To get a specific app service plan, use:
Get-AzureRmAppServicePlan -Name website01

# Configure an existing App Service Plan
# To change the settings for an existing app service plan, use the Set-AzureRmAppServicePlan cmdlet. 
# You can change the tier, worker size, and the number of workers

Set-AzureRmAppServicePlan -Name website01 -ResourceGroupName mywebsites `
-Tier Standard -WorkerSize Medium -NumberofWorkers 9

# Scaling an App Service Plan
# To scale an existing App Service Plan, use:

Set-AzureRmAppServicePlan -Name website01 -ResourceGroupName mywebsites -NumberofWorkers 9

# Changing the worker size of an App Service Plan
# To change the size of workers in an existing App Service Plan, use:

Set-AzureRmAppServicePlan -Name website01 -ResourceGroupName mywebsites -WorkerSize Medium

# Changing the Tier of an App Service Plan
# To change the tier of an existing App Service Plan, use:

Set-AzureRmAppServicePlan -Name website01 -ResourceGroupName mywebsites -Tier Standard

# Delete an existing App Service Plan
# To delete an existing app service plan, all assigned web apps need to be moved or deleted first. 
# Then using the Remove-AzureRmAppServicePlan cmdlet you can delete the app service plan.

Remove-AzureRmAppServicePlan -Name website01 -ResourceGroupName mywebsites

# Managing App Service Web Apps

#########################################################################

#                   Create a Web App                                    #

#########################################################################

# To create a web app, use the New-AzureRmWebApp cmdlet.
# Following are descriptions of the different parameters:
<# 
Name: name for the web app.
AppServicePlan: name for the service plan used to host the web app.
ResourceGroupName: resource group that hosts the App service plan.
Location: the web app location.
#>
# Example to use this cmdlet: name must be unique AZ wide
# maps to *.azurewebsites.net

New-AzureRmWebApp -Name mywebappblahkolke01 -AppServicePlan website01 `
-ResourceGroupName mywebsites01 -Location westus

<# Create a Web App in an App Service Environment
# To create a web app in an App Service Environment (ASE). Use the same New-AzureRmWebApp command with `
# extra parameters to specify the ASE name and the resource group name that the ASE belongs to.

New-AzureRmWebApp -Name MyWebApp -AppServicePlan website01 -ResourceGroupName mywebsites -Location westus  `
-ASEName ContosoASEName -ASEResourceGroupName ContosoASEResourceGroupName

# To learn more about app service environment, check Introduction to App Service Environment
#>

<# Delete an existing Web App

# To delete an existing web app you can use the Remove-AzureRmWebApp cmdlet, you need to specify the name of the web app and the resource group name.

Remove-AzureRmWebApp -Name MyWebAppBlahKolke -ResourceGroupName mywebsites
#>

# To list all web apps under your subscription, use:
Get-AzureRmWebApp
# To list all web apps under a specific resource group, use:
Get-AzureRmWebApp -ResourceGroupname mywebsites
# To get a specific web app, use:
Get-AzureRmWebApp -Name MyWebApp


# Configure an existing Web App

# To change the settings and configurations for an existing web app, use the Set-AzureRmWebApp cmdlet. 
# For a full list of parameters, check the Cmdlet reference docs

# Example (1): use this cmdlet to change connection strings

$connectionstrings = @{ ContosoConn1 = @{ Type = “MySql”; Value = “MySqlConn”}; ContosoConn2 = @{ Type = “SQLAzure”; Value = “SQLAzureConn”} }
Set-AzureRmWebApp -Name MyWebApp -ResourceGroupName mywebsites -ConnectionStrings $connectionstrings

# Example (2): add or change app settings
$appsettings = @{appsetting1 = "appsetting1value"; appsetting2 = "appsetting2value"}
Set-AzureRmWebApp -Name MyWebApp -ResourceGroupName mywebsites -AppSettings $appsettings

# Example (3): set the web app to run in 64-bit mode
Set-AzureRmWebApp -Name MyWebApp -ResourceGroupName mywebsites -Use32BitWorkerProcess $False

# Change the state of an existing Web App

# Restart a web app
# To restart a web app, you must specify the name and resource group of the web app.

Restart-AzureRmWebapp -Name MyWebApp -ResourceGroupName mywebsites

# Stop a web app
# To stop a web app, you must specify the name and resource group of the web app.

Stop-AzureRmWebapp -Name MyWebApp -ResourceGroupName mywebsites

# Start a web app
# To start a web app, you must specify the name and resource group of the web app.

Start-AzureRmWebapp -Name MyWebApp -ResourceGroupName mywebsites

# Manage Web App Publishing profiles

# Each web app has a publishing profile that can be used to publish your apps, several operations can be executed on publishing profiles.

# Get Publishing Profile
# To get the publishing profile for a web app, use:

Get-AzureRmWebAppPublishingProfile -Name MyWebApp -ResourceGroupName mywebsites -OutputFile .\publishingprofile.txt

# This command echoes the publishing profile to the command line as well output the publishing profile to a text file.

# Reset Publishing Profile
# To reset both the publishing password for FTP and web deploy for a web app, use:

Reset-AzureRmWebAppPublishingProfile -Name MyWebApp -ResourceGroupName mywebsites

<# Manage Web App Certificates
To learn about how to manage web app certificates, see SSL Certificates binding using PowerShell
Next Steps

To learn about Azure Resource Manager PowerShell support, see Using Azure PowerShell with Azure Resource Manager.

To learn about App Service Environments, see Introduction to App Service Environment.
    https://docs.microsoft.com/en-us/azure/app-service-web/app-service-app-service-environment-intro

To learn about managing App Service SSL certificates using PowerShell, see SSL Certificates binding using PowerShell.

To learn about the full list of Azure Resource Manager-based PowerShell cmdlets for Azure Web Apps, see Azure Cmdlet Reference of Web Apps Azure Resource Manager PowerShell Cmdlets.
    https://docs.microsoft.com/en-us/powershell/module/azurerm.websites/?view=azurermps-2.2.0

To learn about managing App Service using CLI, see Using Azure Resource Manager-Based XPlat CLI for Azure Web App.
+

#>

