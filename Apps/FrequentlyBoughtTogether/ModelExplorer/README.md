#Model Explorer Web App Code Sample
This sample demonstrates to use HTML5 and client side javascript to explore recommendations from your model.  You can also easily hook up your own catalog and visualize the recommendations.

## Configure the sample for your model
Edit index.html and search for //TODO: comments that show how to configure the sample to use your model and catalog. 

	//TODO: You need to specify your api Key and one or more model name
	var apiKey = "";
	var purchasedModelName = "";
	var viewedModelName = "";
	var fbtModelName = "";
	
	//TODO: override the metadata provider to get info from your catalog
	MetaItemProvider.Default.getMetadataAsync = function(productId)
	{
	    // fetch the metadata for the object
	    return $.getJSON("http://yoursite.com/getmetadata", { productId: productId })
	        .then(function (data)
	        {
	            // map your object to a metadata object
	            return {
	                ProductId: data.property,
	                Name: data.property,
	                Description: data.property,
	                ImageUrl: data.property,
	                Url: data.property,
	                Price: data.property,
	                PriceValue: data.property
	            };
	        });
	};

## Running the sample website
For the sample for function it must be run from an http or https address.  You can use IIS Express or there local web hosting software to host the page and access it from a web browser.

###Item Recommendations
![ModelExplorer][2]

###Cart Recommendations
![ModelExplorer][1]

[1]: ./screenshot1.png
[2]: ./screenshot2.png
