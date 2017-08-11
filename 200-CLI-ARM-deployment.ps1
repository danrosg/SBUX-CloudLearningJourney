# download an ARM template
# Edit paramaters 
# change directory to location of template 

# use to validate a template for deployment
az group deployment validate --resource-group dotnetno3 --template-file template.json --parameters parameters.json

# use to actually deploy 
az group deployment create --resource-group dotnetno3 --template-file template.json --parameters parameters.json

