Notes about my Jenkins experiment. I think the code at the bottom and the articles referenced should help…
 
Read this first:
https://docs.microsoft.com/en-us/azure/jenkins/install-jenkins-solution-template
 
 
I put all my code in GitHub. Set up a personal account.
https://docs.microsoft.com/en-us/azure/jenkins/execute-cli-jenkins-pipeline
Created a token for git
https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
 
 
This is the bomb (service principal setup)
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
 
 
So I setup a website in Github, and created a WebApp in Azure.  Then used Jenkins to do my deploys.
 
In Jenkins: Settings - Git - need to setup token in settings for my Git account
 
In Jenkins: Settings – Azure – need to setup Azure Service Principal in my Jenkins instance
 
 
Once I am ready to deploy my code from GitHub to Azure with Jenkins
1- Login to Jenkins
2- Create new item – select - freestyle and name it
3- no source code (I’m going to use shell to get code from git with my token)
4- Bindings - Select “MSFT Azure Service Principal”
      (need to set up Azure Service Principal / SP in Jenkins prior to this, reference above)
5- Build select “Execute Shell” (this code is my CLI 2.0 script in Jenkins)
 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

gitrepo="https://github.com/mygithubaccount/webapp01.git"
webappname="bobcoeswebapp"
group="WebApp"
token="0cc3024a34db31bguidguidgudigudiguidcdc936746eeac"
 
az login --service-principal --tenant "$AZURE_TENANT_ID" --username "$AZURE_CLIENT_ID" --password "$AZURE_CLIENT_SECRET"
 
az webapp deployment source config --name $webappname --resource-group $group --repo-url $gitrepo --git-token $token --branch master --manual-integration --repository-type git
 
az webapp deployment source sync --name $webappname --resource-group $group
 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
 
6- Save and build
 
7- wait one minute after build (it takes some amount of time)
 
8- goto web app and see if changes are there  ;)
 
 
Yay!
 
