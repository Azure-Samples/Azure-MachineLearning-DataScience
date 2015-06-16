using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net.Http;
using System.Threading.Tasks;
using AzureMLClient.Contracts;

namespace AzureMLClient
{
    public class Client
    {
        private const string WebServiceUriFormat = "workspaces/{0}/webservices/{1}";
      
        public async Task<IEnumerable<WebService>> GetWebServicesAsync()
        {
            using (var httpClient = new HttpClient())
            {
                string uri = string.Format(CultureInfo.InvariantCulture, WebServiceUriFormat, Configurations.WorkspaceId, string.Empty);
                httpClient.DefaultRequestHeaders.Authorization = ClientExtensions.GetAuthorizationHeaderAsync(Configurations.WorkspaceAuthToken);
                var response = await httpClient.GetAsync(new Uri(Configurations.BaseUri, uri)).ConfigureAwait(false);
                return await response.Content.ReadAsAsync<IEnumerable<WebService>>();
            }
        }
    }
}
