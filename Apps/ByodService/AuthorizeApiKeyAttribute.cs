using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;

namespace MarketBasket.Web
{
    
    // Does basic authentication using user provided API keys
    public class ApiKeyAuthorizationAttribute : ActionFilterAttribute
    {
        private string[] apiKeys;

        public ApiKeyAuthorizationAttribute(params string[] apiKeys)
        {
            this.apiKeys = apiKeys;
        }
        
        public override void OnActionExecuting(HttpActionContext actionContext)
        {
            var authHead = actionContext.Request.Headers.Authorization;
            if (authHead != null)
            {
                if (authHead.Scheme.Equals("basic", StringComparison.OrdinalIgnoreCase) && authHead.Parameter != null)
                {
                    var credentials = Encoding.GetEncoding("iso-8859-1").GetString(Convert.FromBase64String(authHead.Parameter));

                    int separator = credentials.IndexOf(':');
                    string username = credentials.Substring(0, separator);
                    string password = credentials.Substring(separator + 1);

                    if (apiKeys.Contains(password))
                    {
                        IUserScopedController controller = actionContext.ControllerContext.Controller as IUserScopedController;
                        if (controller != null && !string.IsNullOrWhiteSpace(username))
                        {
                            controller.UserId = username;
                        }
                        return;
                    }
                }
            }

            actionContext.Response = new HttpResponseMessage(HttpStatusCode.Unauthorized);
            actionContext.Response.Headers.Add("WWW-Authenticate", string.Format("Basic realm=\"{0}\"", actionContext.Request.RequestUri.Host));
        }
    }

    public interface IUserScopedController
    {
        string UserId { get; set; }
    }
    
}
