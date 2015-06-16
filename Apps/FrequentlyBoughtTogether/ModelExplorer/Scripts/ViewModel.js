function ViewModel()
{
    // Data
    var self = this;
    self.explorerKey = ko.observable("").extend({ rateLimit: { method: "notifyWhenChangesStop", timeout: 400 } });
    self.selectedItem = ko.observable();
    self.models = {};

    self.cart = ko.observableArray();
}

function Model(dataService, data)
{
    var self = this;
    if (data)
    {
        $.extend(this, data);
    }

    self.scoreItems = function (items, numResults)
    {
        return ko.extenders.async(self.scoreItemsAsync(items, numResults));
    }

    self.scoreItemsAsync = function (items, numResults)
    {
        var itemId = items.productId || (items.map && items.map(function (i) { return i.productId; })) || items;
        return dataService.getItemRecomendations(self.Id, itemId, numResults);
    }

    self.catalogProducts = ko.pureComputed(function ()
    {
        return dataService.getAllRecomendations(self.Id, 100);
    }).extend({ async: null });

    self.getCatalogProducts = function (results)
    {
        return dataService.getAllRecomendations(self.Id, results);
    };

    self.getMostPopular = function (results)
    {
        dataService.getMostPopular(self.Id, results);
    };
}

function MetaProduct(productId, url, metaItemProvider)
{
    this.productId = productId;

    metaItemProvider = metaItemProvider || MetaItemProvider.GetDefaultProvider(this);

    this.metadata = ko.pureComputed(function ()
    {
        return metaItemProvider.getMetadataAsync(url || productId);
    }, this).extend({ async: null });

    this.scoreThisItem = function ()
    {
        mainViewModel.selectedItem(this);
    }

    this.addToCart = function ()
    {
        var self = this;
        if (mainViewModel.cart().filter(function (i) { return i.productId == self.productId; }).length == 0)
        {
            mainViewModel.cart.push(this);
        }
    }

    this.removeFromCart = function ()
    {
        mainViewModel.cart.remove(this);
    }
}

function MetaItemProvider(defaultTemplate)
{
    var self = this;

    self.urlTemplate = ko.observable(defaultTemplate);
    self.useImageProxy = false;

    self.getMetadataAsync = function (idOrUrl)
    {
        // just use the Product Id for the metadata
        return {
            ProductId: idOrUrl,
            Name: idOrUrl
        };
    }
}


MetaItemProvider.Default = new MetaItemProvider("");

MetaItemProvider.GetDefaultProvider = function (productId)
{
    return MetaItemProvider.Default;
};



MetaProduct.fromIds = function (ids)
{
    // comma deliminated list
    if (ids.split)
        ids = ids.split(",");

    return ids.map(function (i)
    {
        return new MetaProduct(i);
    });
}


function SlicedData(data, sliceSize, rows)
{
    this.data = data;
    rows = rows || 1;

    this.slices = ko.pureComputed(function() 
    {
        var result = [];
        var dataList = ko.unwrap(data);
        if (dataList)
        {
            for (var i = 0; i < dataList.length; i += sliceSize * rows)
            {
                var rowList = [];
                for (var j = i; j < i + sliceSize * rows; j += sliceSize)
                {
                    rowList.push({ values: dataList.slice(j, j + sliceSize) });
                }
                result.push(new Slice(rowList));
            }

            if (result[0]) result[0].activate();

            return result;
        }
    })


    this.nextSlice = function (context, event)
    {
        if (event.relatedTarget)
        {
            var slice = ko.contextFor(event.relatedTarget).$data;
            slice.activate();
            return true;
        }
    };
}

function Slice(rows)
{
    var deferred = $.Deferred();

    this.rows = ko.pureComputed(function ()
    {
        return deferred.then(function () { return rows; });
    }, this).extend({ async: [] });

    this.activate = function () { deferred.resolve(); };
}

// Data provider data model
function MLModels(provider, key)
{
    var self = this;
    var dataService = new provider(key);

    this.models = ko.pureComputed(function ()
    {
        if (key)
            return dataService.getModels();
    }).extend({ async: null });

    this.isValidApiKey = ko.pureComputed(function () { return self.models.success(); });

    this.model = function (name)
    {
        if (self.models() != null)
        {
            return self.models().filter(function (m) { return m.Name == name || m.Id == name; })[0];
        }
    }
}


// Class for calling data market services
function DMService(servicePath, apiKey)
{
    var serviceBasePath = "https://api.datamarket.azure.com/data.ashx/" + servicePath;

    this.getJSON = function (url, data, callback)
    {
        return jQuery.ajax({
            url: serviceBasePath + url,
            type: "get",
            dataType: "json",
            data: data,
            success: callback,
            beforeSend: function (xhr)
            {
                xhr.setRequestHeader("Authorization", "Basic " + window.btoa("AccountKey:" + apiKey));
            }
        });
    }
}


// FBT data Provider
function FBTApi(apiKey)
{
    var dm = new DMService("amla/mba/v1", apiKey);
    var self = this;

    this.getModels = function ()
    {
        return dm.getJSON("/List")
                .then(function (list)
                {
                    return list.value.map(function (d)
                    {
                        var m = new Model(self, d);
                        m.Id = m.Name; 
                        return m;
                    });
                });
    }

    this.getItemRecomendations = function (modelId, itemId)
    {
        return dm.getJSON("/Score", { Id: modelId, "Item": itemId }).then(function (json)
        {
            if (json !== undefined && json.ItemSet != undefined)
            {
                var itemset = new MetaItemSet(json.KeyItem, json.ItemSet, json.Score);
                $.each(itemset.items, function (i, item)
                {
                    item.Rating = json.Score;
                    item.Reasoning = "Most interesting item set for item " + json.KeyItem;
                });
                return itemset;
            }
        });
    }

    this.getAllRecomendations = function (modelId, pageSize, page)
    {
        return dm.getJSON("/ScoredData", { Id: modelId, $top: pageSize, $skip: (page || 0) * pageSize })
                .then(function (list) { return list.value.map(function (d) { return new MetaProduct(d.KeyItem); }); });
    }
}


function MetaItemSet(keyItem, items, score)
{
    this.keyItem = new MetaProduct(keyItem);
    this.items = items.map(function (id) { return new MetaProduct(id) });
    this.score = score.toFixed(3);
    this.totalPrice = ko.pureComputed(function ()
    {
        var total = 0;
        var useTotal = true;
        this.items.forEach(function (item)
        {
            useTotal &= (item.metadata() != null && item.metadata().PriceValue > 0);
            if (useTotal)
            {
                total += item.metadata().PriceValue;
            }
        });
        if (useTotal)
            return total.toFixed(2);
        else
            return 0;
    }, this);

    this.addToCart = function ()
    {
        this.items.forEach(function (i) { i.addToCart(); })
    }
}



// Recommendation data provider
function RecommendationsApi(apiKey)
{
    var dm = new DMService("amla/Recommendations", apiKey);
    var self = this;

    this.getModels = function ()
    {
        return dm.getJSON("/GetAllModels", { apiVersion: "'1.0'" })
                .then(function (list) { return list.d.results.map(function (d) { return new Model(self, d); }); });
    }

    this.getItemRecomendations = function (modelId, items, numResults)
    {
        if (items.join)
            items = items.join();

        return dm.getJSON("/ItemRecommend", { modelId: quote(modelId), itemIds: quote(items), numberOfResults: numResults || 14, includeMetadata: 'False', apiVersion: "'1.0'" }).then(function (json)
        {
            return json.d.results.map(function (d)
            {
                var item = new MetaProduct(d[RecommendationsApi.IdField]);
                item.Rating = d.Rating;
                item.Reasoning = d.Reasoning;
                return item;
            });
        });
    }

    this.getMostPopular = function (modelId, results)
    {
        return dm.getJSON("/GetMostPopular", { modelId: quote(modelId), numberOfResults: results || 14, apiVersion: "'1.0'" }).then(function (json)
        {
            return json.d.results.map(function (d)
            {
                var item = new MetaProduct(d[RecommendationsApi.IdField]);
                item.Rating = d.Rating;
                item.Reasoning = d.Reasoning;
                return item;
            });
        });
    }


    this.getAllRecomendations = function (modelId, pageSize, page)
    {
        return dm.getJSON("/GetCatalog", { modelId: quote(modelId), apiVersion: quote("1.0"), $top: pageSize, $skip: (page || 0) * pageSize })
                .then(function (list)
                {
                    return list.d.results.map(function (d)
                    {
                        return new MetaProduct(d[RecommendationsApi.IdField] || d.ExternalId, d.Description);
                    });
                });
    }
}
RecommendationsApi.IdField = 'Id';


function quote(value)
{
    return "'" + value + "'";
}


function loadTemplates (templateFile)
{
    $.ajax(templateFile, { async: false })
        .success(function (stream)
        {
            $('body').append('<div style="display:none">' + stream + '<\/div>');
        }
    );
};

function trim(str)
{
    return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
}

function EnsureBase64Padding(str)
{
    str = trim(str);
    if (str.length % 2 == 1)
        str += "=";

    if (str.length % 4 == 2)
        return str + "==";
    return str;
}
