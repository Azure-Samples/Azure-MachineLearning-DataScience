using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using AzureMLClient.Contracts;

namespace AzureMLClient
{
    public static class ClientExtensions
    {
        private const string BatchUriFormat = "{0}/jobs/{1}?api-version=2.0";
        private const string EndpointsUriFormat = "workspaces/{0}/webservices/{1}/endpoints";
        private const string UpdateResourceUriFormat = "https://management.azureml.net/workspaces/{0}/webservices/{1}/endpoints/{2}";

        public static async Task<IEnumerable<Endpoint>> GetEndpointsAsync(this WebService webServiece)
        {
            string uri = string.Format(CultureInfo.InvariantCulture, EndpointsUriFormat, webServiece.WorkspaceId, webServiece.Id) + "?decryptSecrets=true";
            using (var httpClient = new HttpClient())
            {
                httpClient.DefaultRequestHeaders.Authorization = GetAuthorizationHeaderAsync(Configurations.WorkspaceAuthToken);
                var response = await httpClient.GetAsync(new Uri(Configurations.BaseUri, uri)).ConfigureAwait(false);
                return await response.Content.ReadAsAsync<IEnumerable<Endpoint>>().ConfigureAwait(false);
            }
        }
        

        public static async Task<BatchStatus> GetBatchStatus(this Endpoint endpoint, string jobId)
        {
            using (var httpClient = new HttpClient())
            {
                var uri = string.Format(CultureInfo.InvariantCulture, BatchUriFormat, endpoint.ApiLocation, jobId);
                httpClient.DefaultRequestHeaders.Authorization = GetAuthorizationHeaderAsync(endpoint.PrimaryKey);
                var response = await httpClient.GetAsync(new Uri(uri)).ConfigureAwait(false);
                return await response.Content.ReadAsAsync<BatchStatus>().ConfigureAwait(false);
            }
        }

        public static async Task<string> SubmitBatch(this Endpoint endpoint, BatchRequest batchRequest)
        {
            using (var httpClient = new HttpClient())
            {
                string uri = endpoint.ApiLocation + "/jobs";
                httpClient.DefaultRequestHeaders.Authorization = GetAuthorizationHeaderAsync(endpoint.PrimaryKey);
                var response = await httpClient.PostAsync(new Uri(uri), new ObjectContent(typeof(BatchRequest), batchRequest, new JsonMediaTypeFormatter())).ConfigureAwait(false);
                return await response.Content.ReadAsAsync<string>().ConfigureAwait(false);
            }
        }

        public static async Task<bool> UpdateResource(this Endpoint endpoint, ResourceLocations resources)
        {
            using (var httpClient = new HttpClient())
            {
                var uri = string.Format(CultureInfo.InvariantCulture, UpdateResourceUriFormat, endpoint.WorkspaceId, endpoint.WebServiceId, endpoint.Name);
                httpClient.DefaultRequestHeaders.Authorization = GetAuthorizationHeaderAsync(endpoint.PrimaryKey);
                httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                var request = new HttpRequestMessage(new HttpMethod("PATCH"), uri);
                request.Content = new ObjectContent(typeof(ResourceLocations), resources, new JsonMediaTypeFormatter());
                var response = await httpClient.SendAsync(request).ConfigureAwait(false);
                if (response.IsSuccessStatusCode)
                {
                    return true;
                }
                return false;
            }
        }

        public static async Task<Endpoint> CreateEndpoint(this WebService webservice, string name, EndpointCreate create, string workspaceAuthToken)
        {
            using (var httpClient = new HttpClient())
            {
                var uri = string.Format(CultureInfo.InvariantCulture, UpdateResourceUriFormat, webservice.WorkspaceId, webservice.Id, name);
                httpClient.DefaultRequestHeaders.Authorization = GetAuthorizationHeaderAsync(workspaceAuthToken);
                httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                var request = new HttpRequestMessage(new HttpMethod("PUT"), uri);
                request.Content = new ObjectContent(typeof(EndpointCreate), create, new JsonMediaTypeFormatter());
                var response = await httpClient.SendAsync(request).ConfigureAwait(false);
                if (response.IsSuccessStatusCode)
                {
                    return await response.Content.ReadAsAsync<Endpoint>().ConfigureAwait(false);
                }
                return null;
            }
        }

        public static bool Completed(this BatchStatus status)
        {
            return status.StatusCode == BatchScoreStatusCode.Cancelled ||
                   status.StatusCode == BatchScoreStatusCode.Failed ||
                   status.StatusCode == BatchScoreStatusCode.Finished;
        }

        public static AuthenticationHeaderValue GetAuthorizationHeaderAsync(string key)
        {
            return new AuthenticationHeaderValue("Bearer", key);
        }

        public static string ToUri(this AzureBlobDataReference blob)
        {
            return blob.BaseLocation + blob.RelativeLocation + blob.SasBlobToken;
        }
    }
}
