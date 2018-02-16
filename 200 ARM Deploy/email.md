####################################################
# POWERSHELL VERSION 
####################################################
# Download an ARM template
# Edit parameters in parameters file
# modify below script with resource group, etc. 
# change FILEPATH to location of template and parameters
# don't remove the ` <- those are very important
####################################################

# Make sure you are logged in   
Login-AzureRMAccount

# use to validate a template for deployment
Test-AzureRmResourceGroupDeployment -ResourceGroupName ExampleResourceGroup `
-TemplateFile c:\MyTemplates\storage.json `
-TemplateParameterFile c:\MyTemplates\storage.parameters.json

# use to actually deploy 
New-AzureRmResourceGroupDeployment -ResourceGroupName ExampleResourceGroup `
-TemplateFile c:\MyTemplates\storage.json `
-TemplateParameterFile c:\MyTemplates\storage.parameters.json


More on this: 
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy

####################################################



