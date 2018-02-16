# download an ARM template
# Edit paramaters 
# change directory to location of template 

# use to validate a template for deployment
az group deployment validate --resource-group wordpress --template-file C:\users\dakolke\desktop\template-CLJ-10\template.json --parameters C:\Users\dakolke\Desktop\template-CLJ-10\parameters.json

# use to actually deploy 
az group deployment create --resource-group wordpress --template-file C:\users\dakolke\desktop\template-CLJ-10\template.json --parameters C:\Users\dakolke\Desktop\template-CLJ-10\parameters.json

# Details and more options:
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli

