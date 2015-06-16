ko.extenders.async = function (computedDeferred, initialValue)
{
    var currentDeferred;
    var asyncComputed;
    var observableValue = ko.observable(initialValue);
    var status = ko.observable("initialValue");

    function createAsyncComputedIfNeeded()
    {
        if (asyncComputed == null)
        {
            asyncComputed = ko.computed(function ()
            {
                if (currentDeferred)
                {
                    currentDeferred.rejectWith("cancelled");
                    currentDeferred = null;
                }

                var newDeferred
                if (typeof computedDeferred == "function")
                    newDeferred = computedDeferred();
                else
                    newDeferred = computedDeferred;

                if (newDeferred && (typeof newDeferred.done == "function"))
                {

                    // It's a deferred
                    status("inProgress");

                    // Create our own wrapper so we can reject
                    currentDeferred = $.Deferred()
                        .done(function (data)
                        {
                            observableValue(data);
                            status("success");
                        })
                        .fail(function ()
                        {
                            if (this != "cancelled")
                            {
                                status("fail");
                            }
                        });

                    newDeferred.done(currentDeferred.resolve);
                    newDeferred.fail(currentDeferred.reject);
                }
                else
                {
                    // A real value, so just publish it immediately
                    observableValue(newDeferred);

                    if (newDeferred == initialValue)
                        status("initialValue");
                    else
                        status("success");

                }
            });
        }
    }

    observableValue.beforeSubscriptionAdd = createAsyncComputedIfNeeded;
    status.beforeSubscriptionAdd = createAsyncComputedIfNeeded;

    observableValue.inProgress = ko.pureComputed(function () { return status() == "inProgress"; });
    observableValue.fail = ko.pureComputed(function () { return status() == "fail"; });
    observableValue.success = ko.pureComputed(function () { return status() == "success"; });
    observableValue.isDefault = ko.pureComputed(function () { return observableValue() == "initialValue"; });

    return observableValue;
};

// Here's a custom Knockout binding that makes elements shown/hidden via jQuery's fadeIn()/fadeOut() methods
// Could be stored in a separate utility library
ko.bindingHandlers.fadeVisible = {
    init: function (element, valueAccessor)
    {
        // Initially set the element to be instantly visible/hidden depending on the value
        var value = valueAccessor();
        $(element).toggle(ko.unwrap(value)); // Use "unwrapObservable" so we can handle values that may or may not be observable
    },
    update: function (element, valueAccessor)
    {
        // Whenever the value subsequently changes, slowly fade the element in or out
        var value = valueAccessor();
        ko.unwrap(value) ? $(element).fadeIn() : $(element).fadeOut();
    }
};

ko.bindingHandlers.uniqueId = {
    init: function (element, valueAccessor)
    {
        element.id = valueAccessor() + (++ko.bindingHandlers.uniqueId.counter);
    },
    counter: 0
};


var uniqueId = function(element)
{
    if (!element.id)
        element.id = "uniqueId" + (++uniqueId.counter);
    return element.id;
}
uniqueId.counter = 0;

ko.bindingContext.prototype.params = {};
var baseTemplate = ko.bindingHandlers.template;
ko.bindingHandlers.template = {
    init: function (element, valueAccessor, allBindings, viewModel, bindingContext)
    {
        var va = ko.bindingHandlers.template.vaProxy.bind(this, valueAccessor, bindingContext);
        return baseTemplate.init(element, va, allBindings, viewModel, bindingContext);

    },
    update: function (element, valueAccessor, allBindings, viewModel, bindingContext)
    {
        var va = ko.bindingHandlers.template.vaProxy.bind(this, valueAccessor, bindingContext, true);

        return baseTemplate.update(element, va, allBindings, viewModel, bindingContext);
    },
    vaProxy: function (valueAccessor, bindingContext, setparams)
    {
        var v = valueAccessor();
        if (setparams && bindingContext && ('data' in v || 'params' in v))
        {
            // force a child binding context to be created if params are used since it has the same data but different params
            if (!('data' in v))
                v.data = bindingContext.$rawData;

            var basefunc = bindingContext.createChildContext;
            bindingContext['createChildContext'] = function (dataValue, as, c)
            {
                //restore the function call the base
                bindingContext['createChildContext'] = basefunc;
                var childContext = basefunc.call(this, dataValue, as, c);

                var params;
                if (childContext.$parentContext)
                    params = Object.create(childContext.$parentContext.params);
                else
                    params = Object.create(ko.bindingContext.prototype.params);

                if (v.params)
                {
                    for (prop in v.params)
                    {
                        params[prop] = v.params[prop];
                    }
                }

                childContext.params = params;

                return childContext;
            }
        }
        if ('data' in v)
            v.data = ko.observable(v.data);
        return v;
    },
    
};