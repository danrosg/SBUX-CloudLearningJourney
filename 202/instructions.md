<h1>ARM Template CosmosDB + Web App Deployment</h1>
<p>
This tutorial shows you how to use an Azure Resource Manager template to deploy and integrate Microsoft Azure Cosmos DB, an Azure App Service web app, and a sample web application.
<p>
Using Azure Resource Manager templates, you can easily automate the deployment and configuration of your Azure resources. This tutorial shows how to deploy a web application and automatically configure Azure Cosmos DB account connection information.
<p>
After completing this tutorial, you will be able to answer the following questions:
<p>
How can I use an Azure Resource Manager template to deploy and integrate an Azure Cosmos DB account and a web app in Azure App Service?
<h3>What to do?</h3>
<ol>
  <li>Save Parameters and Template files to local machine
  <li>Edit the parameters 
  <li>Deploy using the CLI or Powershell deployment scripts (remember to validate before you deploy)
</ol>
<h3>Once deployment is complete</h3>
You can try using the application. simply navigate to the web app URL 
(the URL would be something like http://nameyouenterede.azurewebsites.net). You'll see the following web application:
Sample Todo application

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/create-website/image2.png">

Go ahead and create a couple of tasks in the web app and then return to the Resource group blade in the Azure portal. Click the Azure Cosmos DB account resource in the Resources list and then click Query Explorer. Screenshot of the Summary lens with the web app highlighted

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/create-website/templatedeployment8.png">

Run the default query, "SELECT * FROM c" and inspect the results. Notice that the query has retrieved the JSON representation of the todo items you created in step 7 above. Feel free to experiment with queries; for example, try running SELECT * FROM c WHERE c.isComplete = true to return all todo items which have been marked as complete.

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/create-website/image5.png">
Screenshot of the Query Explorer and Results blades showing the query results


Feel free to explore the Azure Cosmos DB portal experience or modify the sample Todo application. 
<hr>
<p>This is taken from this example https://docs.microsoft.com/en-us/azure/cosmos-db/create-website. We have downloaded the ARM templates already, so you edit locally and deploy. 
<hr>
<h1>About CosmosDB</h1>
<p>Azure Cosmos DB is Microsoft's globally distributed, multi-model database. With the click of a button, Azure Cosmos DB enables you to elastically and independently scale throughput and storage across any number of Azure's geographic regions. It offers throughput, latency, availability, and consistency guarantees with comprehensive service level agreements (SLAs), something no other database service can offer. You can Try Azure Cosmos DB for free without an Azure subscription, free of charge and commitments.
<br>https://docs.microsoft.com/en-us/azure/cosmos-db/introduction

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/introduction/azure-cosmos-db.png">
<hr>
<h1>About Azure Web Apps</h1>
Azure Web Apps enables you to build and host web applications in the programming language of your choice without managing infrastructure. It offers auto-scaling and high availability, supports both Windows and Linux, and enables automated deployments from GitHub, Visual Studio Team Services, or any Git repo. Learn how to use Azure Web Apps with our quickstarts, tutorials, and samples.
<br><br>
https://docs.microsoft.com/en-us/azure/app-service/

<hr>




