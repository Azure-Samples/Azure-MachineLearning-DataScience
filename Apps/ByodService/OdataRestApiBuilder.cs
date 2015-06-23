using Microsoft.Data.Edm;
using Microsoft.Data.Edm.Library;
using Microsoft.Data.Edm.Library.Values;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Reflection;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.OData;
using System.Web.Http.OData.Builder;
using System.Web.Http.OData.Extensions;
using System.Web.Http.OData.Formatter;
using System.Web.Http.OData.Formatter.Deserialization;
using System.Web.Http.OData.Routing;
using System.Web.Http.OData.Routing.Conventions;

namespace MarketBasket.Web
{
    /// <summary>
    /// Creates restful OData API with conventions compatable with the Azure Marketplace, including documentation annotations
    /// </summary>
    public static class OdataActionApiBuilder
    {
        private const string MarketplaceNamespace = "http://schemas.microsoft.com/dallas/2010/04";

        public static ODataRoute MapOdataActionApi<T>(this HttpConfiguration config, string routePrefix) where T : ODataController
        {
            // Use the Controller Namespace and name as the Odata container and schema
            var builder = new ODataConventionModelBuilder();
            builder.Namespace = typeof(T).Namespace;
            builder.ContainerName = typeof(T).Name.Substring(0, typeof(T).Name.LastIndexOf("Controller"));

            // Add any Entity Types from the controller attributes.  The rest will be ComplexTypes
            foreach (var att in typeof(T).GetCustomAttributes<EntitySetAttribute>())
            {
                builder.AddEntitySet(att.EntitySetName, builder.AddEntity(att.EntityType));
            }

            // Discover the Odata actions from controller methods with attributes
            var actions = from m in typeof(T).GetMethods(BindingFlags.Instance | BindingFlags.Public)
                          where Attribute.IsDefined(m, typeof(ODataActionAttribute))
                          select new
                          {
                              Name = m.Name,
                              Description = (m.GetCustomAttribute<DescriptionAttribute>() ?? DescriptionAttribute.Default).Description,
                              ReturnType = m.GetCustomAttribute<ODataActionAttribute>().ReturnType,
                              IsSideEffecting = m.GetCustomAttribute<ODataActionAttribute>().IsSideEffecting,
                              Parameters = from p in m.GetParameters()
                                           select new
                                           {
                                               Name = p.Name,
                                               Description = (p.GetCustomAttribute<DescriptionAttribute>() ?? DescriptionAttribute.Default).Description,
                                               IsOptional = p.IsOptional,
                                               ReturnType = p.ParameterType,
                                               SampleValues = GetSampleValue(p),
                                               EnumValues = GetEnumValues(p)
                                           }
                          };


            // Create Odata Function Imports for all the actions
            foreach (var action in actions)
            {
                // create a Function Import for the action
                var actionConfig = builder.Action(action.Name);
                
                // set the return type
                if (action.ReturnType != null)
                {
                    actionConfig.ReturnType = GetOrAddComplexType(builder, action.ReturnType);

                    // If the Action returns an Entity or collection of entities then we need to associate the action to the EntitySet or serialization will fail 
                    var collectionType = actionConfig.ReturnType as CollectionTypeConfiguration;
                    var entityType = collectionType != null ? collectionType.ElementType : actionConfig.ReturnType;
                    actionConfig.EntitySet = builder.EntitySets.FirstOrDefault(e => e.EntityType == entityType);
                }

                // add the parameters
                foreach (var parameter in action.Parameters)
                {
                    actionConfig.AddParameter(parameter.Name, GetOrAddComplexType(builder, parameter.ReturnType));
                }
            }

           
            // Build the Edm Model for the API
            var model = builder.GetEdmModel();
            
            // Now edit the Edm Model to add Marketplace documentation annotations
            foreach (var functionImport in model.EntityContainers().SelectMany(c => c.FunctionImports()))
            {
                // get the action for the import
                var action = actions.FirstOrDefault(a => a.Name == functionImport.Name);
                if (action != null)
                {
                    // The marketplace doesnt seem to be reading this on the function right now, but lets add it anyway
                    model.AddMarketplaceAnnotation(functionImport, "Description", action.Description);

                    // add the parameter annotations
                    foreach (var parameter in functionImport.Parameters)
                    {
                        // Set the action parameter annotations
                        var actionParam = action.Parameters.First(p => p.Name == parameter.Name);
                        model.AddMarketplaceAnnotation(parameter, "SampleValues", actionParam.SampleValues);
                        model.AddMarketplaceAnnotation(parameter, "Enum", string.Join("|", actionParam.EnumValues));
                        model.AddMarketplaceAnnotation(parameter, "Description", actionParam.Description);
                        
                        // The marketplace is using the IsNullable property to determine if a field is optional.  Unfortunatly this is not public so just use reflection to set it
                        typeof(EdmTypeReference).InvokeMember("isNullable", BindingFlags.SetField | BindingFlags.Instance | BindingFlags.NonPublic, null, parameter.Type, new object[] { actionParam.IsOptional });
                    }
                }
            }

            // add the metadata convention and our action and entityset convention
            var conventions = new List<IODataRoutingConvention>();
            conventions.Add(new MetadataRoutingConvention());
            conventions.Add(new RoutingConvention(typeof(T), builder.ContainerName));

            // Map the model to an Odata Route at the prefix
            return config.Routes.MapODataServiceRoute(routePrefix, routePrefix, model, pathHandler: new DefaultODataPathHandler(), routingConventions: conventions);
        }


        public static void AddMarketplaceAnnotation(this IEdmModel model, IEdmElement element, string name, string value)
        {
            if (!string.IsNullOrEmpty(value))
            {
                model.SetAnnotationValue(element, MarketplaceNamespace, name, new EdmStringConstant(EdmCoreModel.Instance.GetString(true), value));
            }
        }
        private static int GetFormatPrecidence(MediaTypeFormatter formatter)
        {
            if (formatter.SupportedMediaTypes.Any(m => m.MediaType.Contains("atomsvc")))
            {
                return 2;
            }
            else if (formatter.SupportedMediaTypes.Any(m => m.MediaType.Contains("json")))
            {
                return 1;
            }
            else
            {
                return 0;
            }
        }

        private static IEdmTypeConfiguration GetOrAddComplexType(ODataModelBuilder builder, Type type)
        {
            Type collectionType;
            type = GetEnumerableType(type, out collectionType);
            IEdmTypeConfiguration typeConfigurationOrNull = builder.GetTypeConfigurationOrNull(type);
            if (typeConfigurationOrNull == null)
            {
                builder.AddComplexType(type);
                typeConfigurationOrNull = builder.GetTypeConfigurationOrNull(type);
            }
            return collectionType == null ? typeConfigurationOrNull : new CollectionTypeConfiguration(typeConfigurationOrNull, collectionType);
        }

        private static Type GetEnumerableType(Type type, out Type collectionType)
        {
            if (type != typeof(string))
            {
                foreach (Type intType in new Type[] { type }.Union(type.GetInterfaces()))
                {
                    if (intType.IsGenericType && intType.GetGenericTypeDefinition() == typeof(IEnumerable<>))
                    {
                        collectionType = intType;
                        return intType.GetGenericArguments()[0];
                    }
                }
            }
            collectionType = null;
            return type;
        }

        private static string GetSampleValue(ParameterInfo parameter)
        {
            var att = parameter.GetCustomAttribute<SampleValuesAttribute>();
            var value = att != null ? att.SampleValue : parameter.HasDefaultValue ? parameter.DefaultValue : null;
            return value != null ? value.ToString() : null;
        }

        private static IEnumerable<string> GetEnumValues(ParameterInfo parameter)
        {
            var att = parameter.GetCustomAttribute<EnumValuesAttribute>();
            return (att != null && att.EnumValues.Length > 0) ? att.EnumValues.Select(v => v.ToString()) : Enumerable.Empty<string>();
        }

        private class RoutingConvention : IODataRoutingConvention
        {
            private Dictionary<string, string> entitySetActionMap;
            private string controllerName;

            public RoutingConvention(Type controllerType, string controllerName)
            {
                this.controllerName = controllerName;

                // build an action map for entitysets from the controller attributes
                entitySetActionMap = controllerType.GetCustomAttributes<EntitySetAttribute>()
                    .Where(a => !string.IsNullOrEmpty(a.GetAction))
                    .ToDictionary(a => a.EntityType.Name, a => a.GetAction);
            }

            string IODataRoutingConvention.SelectController(ODataPath odataPath, HttpRequestMessage request)
            {
                // Support unbound actions and EntitySet query
                return (odataPath.PathTemplate == "~/action" || odataPath.PathTemplate == "~/entityset") ? controllerName : null;
            }

            string IODataRoutingConvention.SelectAction(ODataPath odataPath, HttpControllerContext controllerContext, ILookup<string, HttpActionDescriptor> actionMap)
            {
                // For EntitySets lookup the get action for the entity set in the dictionary 
                string action = null;
                if (odataPath.PathTemplate == "~/entityset")
                {
                    var entityName = ((EntitySetPathSegment)odataPath.Segments[0]).EntitySet.ElementType.Name;
                    entitySetActionMap.TryGetValue(entityName, out action);
                }

                // for actions assume just get the action name
                if (odataPath.PathTemplate == "~/action")
                {
                    action = ((ActionPathSegment)odataPath.Segments[0]).Action.Name;
                }

                // return the action if it exists, otherwise give another convention a chance at it
                return action != null && actionMap.Contains(action) ? action : null;
            }
        }
    }


    [Serializable]
    [AttributeUsage(AttributeTargets.Method)]
    public class ODataActionAttribute : Attribute, IActionHttpMethodProvider
    {
        private Collection<HttpMethod> methods = new Collection<HttpMethod>();

        public ODataActionAttribute()
        {
            methods.Add(new HttpMethod("GET"));
        }

        public Type ReturnType { get; set;}

        public bool IsSideEffecting { get; set; }

        public Collection<HttpMethod> HttpMethods
        {
            get { return methods; }
        }
    }

    [Serializable]
    [AttributeUsage(AttributeTargets.Class, AllowMultiple=true)]
    public class EntitySetAttribute : Attribute
    {
        public EntitySetAttribute(Type entityType, string name)
        {
            EntityType = entityType;
            EntitySetName = name;
        }

        public Type EntityType { get;  private set; }

        public string EntitySetName { get; private set; }

        public string GetAction { get; set; }
    }


    [Serializable]
    [AttributeUsage(AttributeTargets.Parameter)]
    public class SampleValuesAttribute : Attribute
    {
        public SampleValuesAttribute(object sampleValue)
        {
            SampleValue = sampleValue;
        }

        public object SampleValue { get; private set; }
    }

    [Serializable]
    [AttributeUsage(AttributeTargets.Parameter)]
    public class EnumValuesAttribute : Attribute
    {
        public EnumValuesAttribute(params object[] enumValues)
        {
            EnumValues = enumValues;
        }

        public object[] EnumValues { get; private set; }
    }
}