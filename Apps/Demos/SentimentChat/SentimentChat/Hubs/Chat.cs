using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using SignalR.Hubs;
using System.Net.Http;
using System.Net;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace SignalRChat.Hubs
{
    public class Chat : Hub
    {
        HttpClient httpClient;
        public Chat()
        {
            // Put your Text-Analytics API key below.  Sign up at http://gallery.azureml.net/MachineLearningAPI/6948e0a54fe44e6fb70cbcc143b31298 
            string apikey = "";

            // Intiailize the HTTP Client with the API Key
            var handler = new HttpClientHandler() { Credentials = new NetworkCredential("apikey", apikey) };
            httpClient = new HttpClient(handler);
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        }

        public async Task SendMessage(string name, string message)
        {
            // publish the message
            string id = Guid.NewGuid().ToString();
            Clients.PublishMessage(name, message, id);

            // Call the Text-Analytics GetSentiment API
            var result = await httpClient.GetAsync("https://api.datamarket.azure.com/data.ashx/amla/text-analytics/v1/GetSentiment?text="
                + HttpUtility.UrlEncode(message));
            if (result.IsSuccessStatusCode)
            {
                // parse the json result
                dynamic json = JObject.Parse(await result.Content.ReadAsStringAsync());

                // determine which face to show
                double score = json.Score;
                string sentiment = "neutral";
                if (score < .4)
                    sentiment = "negative";
                else if (score > .65)
                    sentiment = "positive";

                // Send the sentiment
                Clients.PublishSentiment(sentiment, id);
            }
        }
    }
}