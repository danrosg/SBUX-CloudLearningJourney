
Edit the parameters and deploy using the CLI or Powershell deployment templates.

To use the application, simply navigate to the web app URL 
(in the example above, the URL would be http://nameyouenterede.azurewebsites.net). You'll see the following web application:
Sample Todo application

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/create-website/image2.png">

Go ahead and create a couple of tasks in the web app and then return to the Resource group blade in the Azure portal. Click the Azure Cosmos DB account resource in the Resources list and then click Query Explorer. Screenshot of the Summary lens with the web app highlighted

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/create-website/templatedeployment8.png">

Run the default query, "SELECT * FROM c" and inspect the results. Notice that the query has retrieved the JSON representation of the todo items you created in step 7 above. Feel free to experiment with queries; for example, try running SELECT * FROM c WHERE c.isComplete = true to return all todo items which have been marked as complete.

<img src="https://docs.microsoft.com/en-us/azure/cosmos-db/media/create-website/image5.png">
Screenshot of the Query Explorer and Results blades showing the query results


Feel free to explore the Azure Cosmos DB portal experience or modify the sample Todo application. When you're ready, let's deploy another template.
