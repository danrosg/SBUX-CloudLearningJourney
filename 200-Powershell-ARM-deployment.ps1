
# Download an ARM template
# Edit paramaters 
# change directory to location of template 

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


