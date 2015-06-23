using MarketBasket.Web.Controllers;
using System;
using System.Net.Http;
using System.Web;
using System.Web.Http;
using System.Web.Http.Hosting;
using System.Web.Http.WebHost;

namespace MarketBasket.Web
{

    public static class WebApiConfig
    {
        public static void Register(HttpConfiguration config)
        {
            // Use a streaming policy for upload
            config.Services.Replace(typeof(IHostBufferPolicySelector), new NoBufferPolicySelector());

            // Help Controller for UI
            config.Routes.MapHttpRoute(
                name: "Help",
                routeTemplate: "odata/help/{*path}",
                defaults: new { controller = "Help" }
            );

            // Controller for metadata catalog
            config.Routes.MapHttpRoute(
                name: "Catalog",
                routeTemplate: "Metadata",
                defaults: new { controller = "Catalog" }
            );

            // Controller for OAuth
            config.Routes.MapHttpRoute(
                name: "OAuth",
                routeTemplate: "AuthorizeUser",
                defaults: new { controller = "OAuth" }
            );

            // Marketplace Odata API
            config.MapOdataActionApi<FrequentlyBoughtTogetherController>("odata");
        }
    }


    public class NoBufferPolicySelector : WebHostBufferPolicySelector
    {
        public override bool UseBufferedInputStream(object hostContext)
        {

            var context = hostContext as HttpContextBase;
            return context != null && context.Request.HttpMethod == "POST";
        }

        public override bool UseBufferedOutputStream(HttpResponseMessage response)
        {
            return base.UseBufferedOutputStream(response);
        }
    }


}
