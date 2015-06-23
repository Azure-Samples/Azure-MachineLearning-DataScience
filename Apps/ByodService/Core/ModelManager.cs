using AzureMLClient;
using AzureMLClient.Contracts;
using MarketBasket.Web.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace MarketBasket.Core
{
    public class ModelBuilder
    {
        private string userId;
        private string modelName;
        private string trainingTemplateExperimentId;
        private string scoringTemplateExperimentId;
        private string executionExperimentId;
        private ModelDataProvider modelProvider = new ModelDataProvider();
        private Endpoint trainingEndpoint;
        private AzureMLClient.Contracts.WebService scoringWebService;
        private string scoringWorkspaceEndpointToken;


        public ModelBuilder(string userId, string modelName)
        {
            this.userId = userId;
            this.modelName = modelName;

            trainingEndpoint = new Endpoint(){
                ApiLocation =ConfigurationManager.AppSettings["CloudMLTrainingEndpoint"],
                PrimaryKey =ConfigurationManager.AppSettings["CloudMLTrainingEndpointKey"]
            };
            scoringWebService = new AzureMLClient.Contracts.WebService()
            {
                WorkspaceId =ConfigurationManager.AppSettings["CloudMLWorkspaceId"],
                Id =ConfigurationManager.AppSettings["CloudMLScoringWebServiceId"]
            };
            scoringWorkspaceEndpointToken =ConfigurationManager.AppSettings["CloudMLWorkspaceAuthToken"];
        }
        
        public bool TrainModelAsync(bool force = false)
        {
            // Get the Model
            var model = modelProvider.GetModel(userId, modelName);

            if (model == null || string.IsNullOrEmpty(model.DataFileBlobName) || 
                (!force &&(!model.TrainingInvalidated || model.IsTraining)))
            {
                return false;
            }

            // update the status
            UpdateModelStatus("Preparing the Model",
                m => m.IsTraining = true,
                m => m.TrainingStartTime = DateTimeOffset.Now,
                m => m.TrainingEndTime = null);


            // TODO: implement a worker with queue to make model building reliable in the web cluster
            // For now just start a thread
            var thread = new Thread(o =>
            {
                try
                {
                    TrainModel(model);

                }
                catch (Exception e)
                {
                    try
                    {
                        UpdateModelStatus("An error occurred while Training the model.",
                            m => m.IsTraining = false,
                            m => m.TrainingEndTime = DateTimeOffset.Now);
                        
                        Trace.TraceError("Error Building Model {0} for user {1}\n{2}", modelName, userId, e.ToString());
                    }
                    catch { }
                }
            });

            thread.Start();

            return true;
        }


        public void TrainModel(ModelData model)
        {
             // How the model will be identified in Cloud ML
            var modelIdentifier = Guid.NewGuid().ToString().Replace("-", "").Substring(0,24);//userId + "-" + modelName;

            // HACK: temporary workaround issue of webservices failing after 12 hours by extending lease time to 1 year
            //       The fix will be to have a seperate scoring experiment
            string dataReadUrl = modelProvider.GetTemporaryDataFileReadUrl(model.DataFileBlobName, TimeSpan.FromHours(9000));

            // Run the training experiment
            var request = new BatchRequest() { GlobalParameters = new Dictionary<string, string>() };
            request.GlobalParameters["URL"] = dataReadUrl;
            request.GlobalParameters["MaxItemSetSize"] = model.MaxItemSetSize.ToString();
            request.GlobalParameters["SupportThreshhold"] = model.SupportThreshhold.ToString();
            request.GlobalParameters["NumberofSets"] = "1";
            
            var trainingJobId = trainingEndpoint.SubmitBatch(request).Result;

            UpdateModelStatus("Training the Model",
                m => m.ExperimentId = trainingJobId);
            
            // wait for it to finish
            var currentStatus = WaitForCompletion(trainingJobId);

            // if it failed stop
            if (currentStatus.StatusCode != BatchScoreStatusCode.Finished)
            {
                UpdateModelStatus("Error Building Training Model: " + currentStatus.StatusCode + currentStatus.Details);
                return;
            }

            var trainedModel = currentStatus.Results["TrainedModel"];

            UpdateModelStatus("Training the Model");

            // if this is a new endpoint then just retrain it
            Endpoint scoringEndpoint;
            if (model.WebServiceGroupId != null && model.WebServiceGroupId.Length == 24)
            {
                scoringEndpoint = new Endpoint() {
                    ApiLocation = model.ScoringUrl,
                    PrimaryKey = model.ScoringAccessKey,
                    WorkspaceId = scoringWebService.WorkspaceId,
                    WebServiceId = scoringWebService.Id,
                    Name = model.WebServiceGroupId
                };
            }
            else
            {
                // Create the scoring endpoint
                var epCreate = new EndpointCreate(){
                    Description = "",
                    MaxConcurrentCalls = 10,
                    ThrottleLevel = ThrottleLevel.High
                };
                scoringEndpoint = scoringWebService.CreateEndpoint(modelIdentifier, epCreate, scoringWorkspaceEndpointToken).Result;

                if (scoringEndpoint == null)
                {
                    UpdateModelStatus("Error Creating Scoring Endpoint");
                    return;
                }
            }

            // configure it to use the trained model
            if (!scoringEndpoint.UpdateResource(new ResourceLocations() { Resources = new [] { new EndpointResource() {
                Name = "FBT Model",
                Location = trainedModel
            } } }).Result)
            {
                UpdateModelStatus("Error Configuring Scoring Endpoint");
                return;
            }
 
            // test the scoring service
            ValidateScoringEndpoint(scoringEndpoint.ApiLocation, scoringEndpoint.PrimaryKey);

            // All Done
            UpdateModelStatus("Ready",
                m => m.ScoringUrl = scoringEndpoint.ApiLocation,
                m => m.WebServiceGroupId = modelIdentifier,
                m => m.ScoringAccessKey = scoringEndpoint.PrimaryKey,
                m => m.TrainingInvalidated = false,
                m => m.IsTraining = false,
                m => m.TrainingEndTime = DateTimeOffset.Now);
        }

        public void ValidateScoringEndpoint(string url, string accessKey)
        {
            Exception scoreError = null;
            int attemptCount = 0;
            do
            {
                if (++attemptCount > 1)
                {
                    Thread.Sleep(TimeSpan.FromSeconds(3));
                }

                try
                {
                    var prediction = ScoreModel(url, accessKey, "test");
                    scoreError = null;
                }
                catch (Exception e)
                {
                    scoreError = e;
                }
            }
            while (scoreError != null && attemptCount < 6);

            // If we were successfull then try to scale out a few instances for prompt service reponse time
            if (scoreError == null)
            {
                for (int i = 8; i <= 10; i += 2)
                {
                    List<Task> calls = new List<Task>();
                    for (int j = 0; j < i; j++)
                    {
                        calls.Add(Task.Run(() =>
                        { 
                            try { ScoreModel(url, accessKey, "test"); }
                            catch {/* ignore errors */}
                        }));
                    }
                    Task.WaitAll(calls.ToArray(), TimeSpan.FromSeconds(15));
                    Thread.Sleep(TimeSpan.FromSeconds(1));
                }
            }
        }

        private BatchStatus WaitForCompletion(string jobId)
        {
            BatchStatus currentStatus;
            while (true)
            {
                currentStatus = trainingEndpoint.GetBatchStatus(jobId).Result;
                if (currentStatus.Completed())
                {
                    break;
                }
                Thread.Sleep(TimeSpan.FromSeconds(5));
            }
            return currentStatus;
        }

        

        public Prediction ScoreModel(string item, IEnumerable<KeyValuePair<string, string>> headers = null)
        {
            var model = modelProvider.GetModel(userId, modelName);
            return ScoreModel(model.ScoringUrl, model.ScoringAccessKey, item, headers);
        }

        private Prediction ScoreModel(string url, string accessKey, string item, IEnumerable<KeyValuePair<string,string>> headers = null)
        {
            if (url == null || accessKey == null)
            {
                return null;
            }

            Dictionary<string, string> features = new Dictionary<string, string>();
            features["Item"] = item;
            
            var gParams = new Dictionary<string, string>();

            // new retraining api schema
            if (!url.EndsWith("/score"))
            {
                url = url + "/score";
                gParams["NumberOfResults"] = "1";
            }

            var result = Score<Prediction>(
                url,
                accessKey,
                features,
                gParams,
                (data) =>
                {
                    double score;
                    return new Prediction()
                    {
                        KeyItem = data[0],
                        ItemSet = new string[] { data[0] }.Union(data[1].Split(',')).ToArray(),
                        Score = double.TryParse(data[2], out score) ? score : -1
                    };
                }, true, headers);

            return result.Count > 0 ? result[0] : null;
        }

        private void UpdateModelStatus(string status, params Action<ModelData>[] otherParams)
        {
            var model = modelProvider.GetModel(userId, modelName);
            
            model.Status = status;
            foreach (var action in otherParams)
            {
                action(model);
            }

            modelProvider.UpdateModel(model);
        }


        /// <summary>
        /// Call the end point of a scoring experiment and return the results
        /// may throw an ApiException if parsing fails
        /// </summary>
        /// <param name="webServiceUri">scoring web service end point URI</param>
        /// <param name="apiKey">scoring web service API key</param>
        /// <param name="featureVector">feature vector</param>
        /// <param name="globalParameters">global parameters</param>
        /// <param name="singleResultInitialization">initialization method for generating response entries</param>
        /// <param name="isMultipleResults">true to return multiple results (when available), false to return only one result</param>
        /// <returns>scoring results</returns>
        private static IList<T> Score<T>(string webServiceUri, string apiKey, Dictionary<string, string> featureVector, Dictionary<string, string> globalParameters, Func<string[], T> singleResultInitialization, bool isMultipleResults = false, IEnumerable<KeyValuePair<string, string>> headers = null)
        {
            ScoreData scoreData = new ScoreData
            {
                FeatureVector = featureVector ?? new Dictionary<string, string>(),
                GlobalParameters = globalParameters ?? new Dictionary<string, string>()
            };

            ScoreRequest scoreRequest = new ScoreRequest
            {
                Id = Guid.NewGuid().ToString(),
                Instance = scoreData
            };



            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

                // add any custom headers
                if (headers != null)
                {
                    foreach (var header in headers)
                    {
                        client.DefaultRequestHeaders.Add(header.Key, header.Value);
                    }
                }

                client.BaseAddress = FormatUri(webServiceUri, isMultipleResults);
                HttpResponseMessage response = client.PostAsJsonAsync("", scoreRequest).Result;
                if (!response.IsSuccessStatusCode)
                {
                    // format all the headers of the response
                    var headersString = new StringBuilder();
                    if (response.Headers != null)
                    {
                        foreach (var header in response.Headers)
                        {
                            headersString.AppendFormat("{0}: {1} {2}", header.Key, string.Join(",", header.Value), Environment.NewLine);
                        }
                    }
                    // once an error happens, collect the response reason + http status + headers to better handle the error
                    throw new ApplicationException(string.Format("Error getting scoring results: error code: {1} , reason reported:{0} , response headers: {2}", (int)response.StatusCode, response.ReasonPhrase ?? string.Empty, headersString.ToString()));
                }

                return ParseResponse(response.Content.ReadAsStringAsync().Result, singleResultInitialization);
            }
        }

        /// <summary>
        /// parses the response from the experiment, by activating the <see cref="singleResultInitialization"/> method over each string array in the response.
        /// may throw an ApiException if fails
        /// </summary>
        /// <typeparam name="T">type to return</typeparam>
        /// <param name="encodedString">response from the remote experiment</param>
        /// <param name="singleResultInitialization">initialization method for generating response entries</param>
        /// <returns>a list of <see cref="T"/> results</returns>
        private static IList<T> ParseResponse<T>(string encodedString, Func<string[], T> singleResultInitialization)
        {
            if (singleResultInitialization == null)
            {
                throw new ApplicationException("Initialization method for scoring is null");
            }
            try
            {
                var items = JsonConvert.DeserializeObject<string[][]>(encodedString);
                return items.Select(singleResultInitialization).ToList();
            }
            catch (Exception e)
            {
                throw new ApplicationException(string.Format("Bad format in response from experiment {0}", encodedString), e);
            }
        }

        /// <summary>
        /// Format the CloudML service URI, including multi row handling
        /// </summary>
        /// <param name="baseUri">CloudML base service URI</param>
        /// <param name="isMultipleRows">true to allow multiple results</param>
        /// <returns>formatted URI</returns>
        private static Uri FormatUri(string baseUri, bool isMultipleRows)
        {
            if (baseUri.EndsWith("/"))
            {
                baseUri = baseUri.Remove(baseUri.Length - 1);
            }

            return new Uri(isMultipleRows ? baseUri + "MultiRow" : baseUri);
        }

        public class ScoreData
        {
            /// <summary>
            /// Feature vector
            /// </summary>
            public Dictionary<string, string> FeatureVector { get; set; }

            /// <summary>
            /// Global parameters
            /// </summary>
            public Dictionary<string, string> GlobalParameters { get; set; }
        }


        /// <summary>
        /// Contains data to be sent as a request to a scoring experiment
        /// </summary>
        public class ScoreRequest
        {
            /// <summary>
            /// Request ID
            /// </summary>
            public string Id { get; set; }
        
            /// <summary>
            /// Scoring parameters
            /// </summary>
            public ScoreData Instance { get; set; }
        }
    }
}
