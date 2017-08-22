
# Download an ARM template
# Edit paramaters 
# change directory to location of template 

# use to validate a template for deployment
Test-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName ExampleResourceGroup `
-TemplateFile c:\MyTemplates\storage.json `
-TemplateParameterFile c:\MyTemplates\storage.parameters.json

# use to actually deploy 
New-AzureRmResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName ExampleResourceGroup `
-TemplateFile c:\MyTemplates\storage.json `
-TemplateParameterFile c:\MyTemplates\storage.parameters.json


