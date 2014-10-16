#JosephMart Code Sample
Deploy a fully featured retail website and customize it with Frequently Bought Together Recommendations in a just few minutes.

## Creating the website
You can use WebMatrix to quickly deploy a retail website directly to Azure in just a few minutes.

1. Install and run [Microsoft WebMatrix](http://www.microsoft.com/web/webmatrix/)
2.	Create a new nopComerse site from the App Gallery
3.	After it installs note the SqlAzure server name and wait for the admin UI to open in the browser
4.	Select the **Add Demo data box** and Enter your credentials making sure to specify the Azure Sql Server name that was created in your subscription
5.	After it is setup, go to WebMatrix and hit publish.

## Training Data
Historical transactions for the demo website data that can be used to train a model can be found in the [JosephMartTransactions.csv](./JosephMartTransactions.csv).

## Integrating Frequently Bought Together recommendations into the website
Code for all the changes made to the default website are in this folder.  You can see the specific changes by reviewing [ChangeSet 19722cd](https://github.com/Azure/Azure-MachineLearning-DataScience/commit/19722cd86d1d6de0ffda4ed11d0d152488e2436f).  Notably the 3 lines added that enable this feature are:

	@{
    // Call the Marketplace api to get the Frequently Bought Together products for this product
    var prediction = GetJsonObject("https://api.datamarket.azure.com/data.ashx/amla/mba/v1/Score?Id=<YOUR_MODEL_NAME>&Item=" + Product.Id,
        "AccountKey", "<YOUR_API_KEY>");

    // Get the product information from the Database
    List<ProductOverviewModel> boughtTogether = GetProducts(prediction.ItemSet);
	}

	<!-- Apply HTML template for the Frequently Bought Together Products -->
	@Html.Partial("FrequentlyBoughtTogether", boughtTogether)  


###Screenshot of the completed web page
![JosephMart][1]

[1]: ./screenshot.jpg
