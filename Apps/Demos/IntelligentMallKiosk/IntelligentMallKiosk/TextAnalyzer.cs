using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Web;
using System.Configuration;

namespace MLMarketplaceDemo
{
    static class TextAnalyzer
    {

        private static Configuration configManager = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);

        //// Copying sentiment code
        private const string ServiceBaseUri = "https://api.datamarket.azure.com/";
        public static TextAnalysisResult AnalyzeText(string inputText)
        {
            KeyValueConfigurationCollection confCollection = configManager.AppSettings.Settings;
            string accountKey = confCollection["TextAnalyticsAPIKey"].Value;  

            KeyPhraseResult keyPhraseResult;
            SentimentResult sentimentResult;

            if (inputText == null)
            {
                keyPhraseResult = new KeyPhraseResult();
                keyPhraseResult.KeyPhrases = new List<string>();
                sentimentResult = new SentimentResult() { Score = 0.5 };
                
            }
            else using (var httpClient = new HttpClient())
            {
                string inputTextEncoded = HttpUtility.UrlEncode(inputText);
                httpClient.BaseAddress = new Uri(ServiceBaseUri);
                string creds = "AccountKey:" + accountKey;
                string authorizationHeader = "Basic " + Convert.ToBase64String(Encoding.ASCII.GetBytes(creds));
                httpClient.DefaultRequestHeaders.Add("Authorization", authorizationHeader);
                httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));


                // get key phrases
                string keyPhrasesRequest = "data.ashx/amla/text-analytics/v1/GetKeyPhrases?Text=" + inputTextEncoded;
                Task<HttpResponseMessage> responseTask = httpClient.GetAsync(keyPhrasesRequest);
                responseTask.Wait();
                HttpResponseMessage response = responseTask.Result;
                Task<string> contentTask = response.Content.ReadAsStringAsync();
                contentTask.Wait();
                string content = contentTask.Result;
                if (!response.IsSuccessStatusCode)
                {
                    throw new Exception("Call to get key phrases failed with HTTP status code: " +
                                        response.StatusCode + " and contents: " + content);
                }
                keyPhraseResult = JsonConvert.DeserializeObject<KeyPhraseResult>(content);
                Console.WriteLine("Key phrases: " + string.Join(",", keyPhraseResult.KeyPhrases));
                // get sentiment
                string sentimentRequest = "data.ashx/amla/text-analytics/v1/GetSentiment?Text=" + inputTextEncoded;
                responseTask = httpClient.GetAsync(sentimentRequest);
                responseTask.Wait();
                response = responseTask.Result;
                contentTask = response.Content.ReadAsStringAsync();
                contentTask.Wait();
                content = contentTask.Result;
                if (!response.IsSuccessStatusCode)
                {
                    throw new Exception("Call to get sentiment failed with HTTP status code: " +
                                        response.StatusCode + " and contents: " + content);
                }
                sentimentResult = JsonConvert.DeserializeObject<SentimentResult>(content);
                Console.WriteLine("Sentiment score: " + sentimentResult.Score);
            }

            TextAnalysisResult result = new TextAnalysisResult()
            {
                KeyPhrases = keyPhraseResult.KeyPhrases,
                Score = sentimentResult.Score
            };

            return result;

        }
    }

    public struct TextAnalysisResult
    {
        public List<string> KeyPhrases { get; set; }
        public double Score { get; set; }
    }

    /// <summary>
    /// Class to hold result of Key Phrases call
    /// </summary>
    internal class KeyPhraseResult
    {
        public List<string> KeyPhrases { get; set; }
    }
    /// <summary>
    /// Class to hold result of Sentiment call
    /// </summary>
    internal  class SentimentResult
    {
        public double Score { get; set; }
    }


}
