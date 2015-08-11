// *********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
// *********************************************************

namespace Microsoft.ProjectOxford.Face
{
    using System;
    using System.Dynamic;
    using System.IO;
    using System.Net;
    using System.Threading.Tasks;
    using Microsoft.ProjectOxford.Face.Contract;
    using Newtonsoft.Json;
    using Newtonsoft.Json.Serialization;

    /// <summary>
    /// The face service client proxy implementation.
    /// </summary>
    public class FaceServiceClient : IFaceServiceClient
    {
        #region private members

        /// <summary>
        /// The service host.
        /// </summary>
        private const string ServiceHost = "https://api.projectoxford.ai/face/v0"; //"https://is.azure-api.net/face/v0";

        /// <summary>
        /// The subscription key name.
        /// </summary>
        private const string SubscriptionKeyName = "subscription-key";

        /// <summary>
        /// The detection.
        /// </summary>
        private const string DetectionsQuery = "detections";

        /// <summary>
        /// The verification.
        /// </summary>
        private const string VerificationsQuery = "verifications";

        /// <summary>
        /// The model training query.
        /// </summary>
        private const string ModelTrainingQuery = "training";

        /// <summary>
        /// The person groups.
        /// </summary>
        private const string PersonGroupsQuery = "persongroups";

        /// <summary>
        /// The persons.
        /// </summary>
        private const string PersonsQuery = "persons";

        /// <summary>
        /// The faces query string.
        /// </summary>
        private const string FacesQuery = "faces";

        /// <summary>
        /// The identifications.
        /// </summary>
        private const string IdentificationsQuery = "identifications";

        /// <summary>
        /// The subscription key.
        /// </summary>
        private string subscriptionKey;

        /// <summary>
        /// The default resolver.
        /// </summary>
        private CamelCasePropertyNamesContractResolver defaultResolver = new CamelCasePropertyNamesContractResolver();

        #endregion

        /// <summary>
        /// Initializes a new instance of the <see cref="FaceServiceClient"/> class.
        /// </summary>
        /// <param name="subscriptionKey">The subscription key.</param>
        public FaceServiceClient(string subscriptionKey)
        {
            this.subscriptionKey = subscriptionKey;
        }

        #region IFaceServiceClient implementations

        /// <summary>
        /// Detects an URL asynchronously.
        /// </summary>
        /// <param name="url">The URL.</param>
        /// <param name="analyzesFacialLandmarks">If set to <c>true</c> [analyzes facial landmarks].</param>
        /// <param name="analyzesAge">If set to <c>true</c> [analyzes age].</param>
        /// <param name="analyzesGender">If set to <c>true</c> [analyzes gender].</param>
        /// <param name="analyzesHeadPose">If set to <c>true</c> [analyzes head pose].</param>
        /// <returns>The detected faces.</returns>
        public async Task<Face[]> DetectAsync(string url, bool analyzesFacialLandmarks = false, bool analyzesAge = false, bool analyzesGender = false, bool analyzesHeadPose = false)
        {
            var requestUrl = string.Format(
                "{0}/{1}?analyzesFacialLandmarks={2}&analyzesAge={3}&analyzesGender={4}&analyzesHeadPose={5}&{6}={7}",
                ServiceHost,
                DetectionsQuery,
                analyzesFacialLandmarks,
                analyzesAge,
                analyzesGender,
                analyzesHeadPose,
                SubscriptionKeyName,
                this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.url = url;

            return await this.SendAsync<ExpandoObject, Face[]>("POST", requestBody, request).ConfigureAwait(false); 
        }

        /// <summary>
        /// Detects an image asynchronously.
        /// </summary>
        /// <param name="imageStream">The image stream.</param>
        /// <param name="analyzesFacialLandmarks">If set to <c>true</c> [analyzes facial landmarks].</param>
        /// <param name="analyzesAge">If set to <c>true</c> [analyzes age].</param>
        /// <param name="analyzesGender">If set to <c>true</c> [analyzes gender].</param>
        /// <param name="analyzesHeadPose">If set to <c>true</c> [analyzes head pose].</param>
        /// <returns>The detected faces.</returns>
        public async Task<Face[]> DetectAsync(Stream imageStream, bool analyzesFacialLandmarks = false, bool analyzesAge = false, bool analyzesGender = false, bool analyzesHeadPose = false)
        {
            var requestUrl = string.Format(
                "{0}/{1}?analyzesFacialLandmarks={2}&analyzesAge={3}&analyzesGender={4}&analyzesHeadPose={5}&{6}={7}",
                ServiceHost,
                DetectionsQuery,
                analyzesFacialLandmarks,
                analyzesAge,
                analyzesGender,
                analyzesHeadPose,
                SubscriptionKeyName,
                this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.SendAsync<Stream, Face[]>("POST", imageStream, request);
        }


        public async Task<Face[]> DetectAsync2(Stream imageStream, bool analyzesFacialLandmarks = false, bool analyzesAge = false, bool analyzesGender = false, bool analyzesHeadPose = false)
        {
            var requestUrl = string.Format(
                "{0}/{1}?analyzesFacialLandmarks={2}&analyzesAge={3}&analyzesGender={4}&analyzesHeadPose={5}&{6}={7}",
                ServiceHost,
                DetectionsQuery,
                analyzesFacialLandmarks,
                analyzesAge,
                analyzesGender,
                analyzesHeadPose,
                SubscriptionKeyName,
                this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            request.Method = "POST";

            this.SetCommonHeaders(request);
            request.ContentType = "application/octet-stream";

            Stream requestStream = await request.GetRequestStreamAsync();

            imageStream.CopyTo(requestStream);

            WebResponse response = await request.GetResponseAsync();

            return this.ProcessAsyncResponse<Face[]> (response as HttpWebResponse);
        }



        /// <summary>
        /// Verifies whether the specified two faces belong to the same person asynchronously.
        /// </summary>
        /// <param name="faceId1">The face id 1.</param>
        /// <param name="faceId2">The face id 2.</param>
        /// <returns>The verification result.</returns>
        public async Task<VerifyResult> VerifyAsync(Guid faceId1, Guid faceId2)
        {
            var requestUrl = string.Format("{0}/{1}?{2}={3}", ServiceHost, VerificationsQuery, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.faceId1 = faceId1;
            requestBody.faceId2 = faceId2;

            return await this.SendAsync<ExpandoObject, VerifyResult>("POST", requestBody, request);
        }

        /// <summary>
        /// Identities the faces in a given person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <param name="maxNumOfCandidatesReturned">The maximum number of candidates returned for each face.</param>
        /// <returns>The identification results</returns>
        public async Task<IdentifyResult[]> IdentityAsync(string personGroupId, Guid[] faceIds, int maxNumOfCandidatesReturned = 1)
        {
            var requestUrl = string.Format("{0}/{1}?{2}={3}", ServiceHost, IdentificationsQuery, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.personGroupId = personGroupId;
            requestBody.faceIds = faceIds;
            requestBody.maxNumOfCandidatesReturned = maxNumOfCandidatesReturned;

            return await this.SendAsync<ExpandoObject, IdentifyResult[]>("POST", requestBody, request);
        }

        /// <summary>
        /// Creates the person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group identifier.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        public async Task CreatePersonGroupAsync(string personGroupId, string name, string userData = null)
        {
            var requestUrl = string.Format("{0}/{1}/{2}?{3}={4}", ServiceHost, PersonGroupsQuery, personGroupId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.name = name;
            requestBody.userData = userData;

            await this.SendAsync<ExpandoObject, object>("PUT", requestBody, request);
        }

        /// <summary>
        /// Gets a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>The person group entity.</returns>
        public async Task<PersonGroup> GetPersonGroupAsync(string personGroupId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}?{3}={4}", ServiceHost, PersonGroupsQuery, personGroupId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.GetAsync<PersonGroup>("GET", request);
        }

        /// <summary>
        /// Updates a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        public async Task UpdatePersonGroupAsync(string personGroupId, string name, string userData = null)
        {
            var requestUrl = string.Format("{0}/{1}/{2}?{3}={4}", ServiceHost, PersonGroupsQuery, personGroupId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.name = name;
            requestBody.userData = userData;

            await this.SendAsync<ExpandoObject, PersonGroup>("PATCH", requestBody, request);
        }

        /// <summary>
        /// Deletes a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>Task object.</returns>
        public async Task DeletePersonGroupAsync(string personGroupId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}?{3}={4}", ServiceHost, PersonGroupsQuery, personGroupId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            await this.GetAsync<object>("DELETE", request);
        }

        /// <summary>
        /// Gets all person groups asynchronously.
        /// </summary>
        /// <returns>Person group entity array.</returns>
        public async Task<PersonGroup[]> GetPersonGroupsAsync()
        {
            var requestUrl = string.Format(
                "{0}/{1}?{2}={3}",
                ServiceHost,
                PersonGroupsQuery,
                SubscriptionKeyName,
                this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.GetAsync<PersonGroup[]>("Get", request);
        }

        /// <summary>
        /// Trains the person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>Task object.</returns>
        public async Task TrainPersonGroupAsync(string personGroupId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}?{4}={5}", ServiceHost, PersonGroupsQuery, personGroupId, ModelTrainingQuery, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            await this.SendAsync<object, object>("POST", null, request);
        }

        /// <summary>
        /// Gets person group training status asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>The person group training status.</returns>
        public async Task<TrainingStatus> GetPersonGroupTrainingStatusAsync(string personGroupId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}?{4}={5}", ServiceHost, PersonGroupsQuery, personGroupId, ModelTrainingQuery, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.GetAsync<TrainingStatus>("GET", request);
        }

        /// <summary>
        /// Creates a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>The CreatePersonResult entity.</returns>
        public async Task<PersonCreationResponse> CreatePersonAsync(string personGroupId, Guid[] faceIds, string name, string userData = null)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}?{4}={5}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.faceIds = faceIds;
            requestBody.name = name;
            requestBody.userData = userData;

            return await this.SendAsync<ExpandoObject, PersonCreationResponse>("POST", requestBody, request);
        }

        /// <summary>
        /// Gets a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <returns>The person entity.</returns>
        public async Task<Person> GetPersonAsync(string personGroupId, Guid personId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}?{5}={6}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.GetAsync<Person>("Get", request);
        }

        /// <summary>
        /// Updates a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <param name="name">The name.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>Task object.</returns>
        public async Task UpdatePersonAsync(string personGroupId, Guid personId, Guid[] faceIds, string name, string userData = null)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}?{5}={6}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.faceIds = faceIds;
            requestBody.name = name;
            requestBody.userData = userData;

            await this.SendAsync<object, object>("PATCH", requestBody, request);
        }

        /// <summary>
        /// Deletes a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <returns>Task object.</returns>
        public async Task DeletePersonAsync(string personGroupId, Guid personId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}?{5}={6}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            await this.GetAsync<object>("DELETE", request);
        }

        /// <summary>
        /// Gets all persons inside a person group asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <returns>
        /// The person entity array.
        /// </returns>
        public async Task<Person[]> GetPersonsAsync(string personGroupId)
        {
            var requestUrl = string.Format(
                "{0}/{1}/{2}/{3}?{4}={5}",
                ServiceHost,
                PersonGroupsQuery,
                personGroupId,
                PersonsQuery,
                SubscriptionKeyName,
                this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.GetAsync<Person[]>("Get", request);
        }

        /// <summary>
        /// Adds a face to a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>
        /// Task object.
        /// </returns>
        public async Task AddPersonFaceAsync(string personGroupId, Guid personId, Guid faceId, string userData = null)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}/{5}/{6}?{7}={8}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, FacesQuery, faceId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.userData = userData;

            await this.SendAsync<ExpandoObject, object>("PUT", requestBody, request);
        }

        /// <summary>
        /// Gets a face of a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <returns>
        /// The person face entity.
        /// </returns>
        public async Task<PersonFace> GetPersonFaceAsync(string personGroupId, Guid personId, Guid faceId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}/{5}/{6}?{7}={8}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, FacesQuery, faceId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            return await this.GetAsync<PersonFace>("GET", request);
        }

        /// <summary>
        /// Updates a face of a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <param name="userData">The user data.</param>
        /// <returns>
        /// Task object.
        /// </returns>
        public async Task UpdatePersonFaceAsync(string personGroupId, Guid personId, Guid faceId, string userData)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}/{5}/{6}?{7}={8}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, FacesQuery, faceId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.userData = userData;

            await this.SendAsync<ExpandoObject, object>("PATCH", requestBody, request);
        }

        /// <summary>
        /// Deletes a face of a person asynchronously.
        /// </summary>
        /// <param name="personGroupId">The person group id.</param>
        /// <param name="personId">The person id.</param>
        /// <param name="faceId">The face id.</param>
        /// <returns>
        /// Task object.
        /// </returns>
        public async Task DeletePersonFaceAsync(string personGroupId, Guid personId, Guid faceId)
        {
            var requestUrl = string.Format("{0}/{1}/{2}/{3}/{4}/{5}/{6}?{7}={8}", ServiceHost, PersonGroupsQuery, personGroupId, PersonsQuery, personId, FacesQuery, faceId, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            await this.GetAsync<object>("DELETE", request);
        }

        /// <summary>
        /// Finds the similar faces.
        /// </summary>
        /// <param name="faceId">The face identifier.</param>
        /// <param name="faceIds">The face ids.</param>
        /// <returns>
        /// Task object.
        /// </returns>
        public async Task<SimilarFace[]> FindSimilarAsync(Guid faceId, Guid[] faceIds)
        {
            var requestUrl = string.Format("{0}/findsimilars?{1}={2}", ServiceHost, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.faceId = faceId;
            requestBody.faceIds = faceIds;

            return await this.SendAsync<ExpandoObject, SimilarFace[]>("POST", requestBody, request);
        }

        /// <summary>
        /// Groups the face.
        /// </summary>
        /// <param name="faceIds">The face ids.</param>
        /// <returns>
        /// Task object.
        /// </returns>
        public async Task<GroupResult> GroupAsync(Guid[] faceIds)
        {
            var requestUrl = string.Format("{0}/groupings?{1}={2}", ServiceHost, SubscriptionKeyName, this.subscriptionKey);
            var request = WebRequest.Create(requestUrl);

            dynamic requestBody = new ExpandoObject();
            requestBody.faceIds = faceIds;

            return await this.SendAsync<ExpandoObject, GroupResult>("POST", requestBody, request);
        }
        #endregion

        #region the json client

        /// <summary>
        /// Gets the asynchronous.
        /// </summary>
        /// <typeparam name="TResponse">The type of the response.</typeparam>
        /// <param name="method">The method.</param>
        /// <param name="request">The request.</param>
        /// <param name="setHeadersCallback">The set headers callback.</param>
        /// <returns>
        /// The task.
        /// </returns>
        private async Task<TResponse> GetAsync<TResponse>(string method, WebRequest request, Action<WebRequest> setHeadersCallback = null)
        {
            if (request == null)
            {
                new ArgumentNullException("request");
            }

            try
            {
                request.Method = method;
                if (null == setHeadersCallback)
                {
                    this.SetCommonHeaders(request);
                }
                else
                {
                    setHeadersCallback(request);
                }

                var response = await Task.Factory.FromAsync<WebResponse>(
                    request.BeginGetResponse,
                    request.EndGetResponse,
                    null);

                return this.ProcessAsyncResponse<TResponse>(response as HttpWebResponse);
            }
            catch (Exception e)
            {
                this.HandleException(e);
                return default(TResponse);
            }
        }

        /// <summary>
        /// The helper method to do post or put async with rest call.
        /// </summary>
        /// <typeparam name="TRequest">Type of request.</typeparam>
        /// <typeparam name="TResponse">Type of response.</typeparam>
        /// <param name="method">Http method.</param>
        /// <param name="requestBody">Request data object.</param>
        /// <param name="request">Request parameter.</param>
        /// <param name="setHeadersCallback">The set headers callback.</param>
        /// <returns>
        /// The task object.
        /// </returns>
        /// <exception cref="System.ArgumentNullException">The request.</exception>
        private async Task<TResponse> SendAsync<TRequest, TResponse>(string method, TRequest requestBody, WebRequest request, Action<WebRequest> setHeadersCallback = null)
        {
            try
            {
                if (request == null)
                {
                    throw new ArgumentNullException("request");
                }

                request.Method = method;
                if (null == setHeadersCallback)
                {
                    this.SetCommonHeaders(request);
                }
                else
                {
                    setHeadersCallback(request);
                }

                if (requestBody is Stream)
                {
                    request.ContentType = "application/octet-stream";
                }

                var asyncState = new WebRequestAsyncState()
                {
                    RequestBytes = this.SerializeRequestBody(requestBody),
                    WebRequest = (HttpWebRequest)request,
                };

                var continueRequestAsyncState = await Task.Factory.FromAsync<Stream>(
                                                    asyncState.WebRequest.BeginGetRequestStream,
                                                    asyncState.WebRequest.EndGetRequestStream,
                                                    asyncState,
                                                    TaskCreationOptions.None).ContinueWith<WebRequestAsyncState>(
                                                       task =>
                                                       {
                                                           var requestAsyncState = (WebRequestAsyncState)task.AsyncState;
                                                           if (requestBody != null)
                                                           {
                                                               using (var requestStream = task.Result)
                                                               {
                                                                   if (requestBody is Stream)
                                                                   {
                                                                       var inputStream = requestBody as Stream;
                                                                       inputStream.CopyTo(requestStream);
                                                                   }
                                                                   else
                                                                   {
                                                                       requestStream.Write(requestAsyncState.RequestBytes, 0, requestAsyncState.RequestBytes.Length);
                                                                   }
                                                               }
                                                           }

                                                           return requestAsyncState;
                                                       });

                var continueWebRequest = continueRequestAsyncState.WebRequest;
                var response = await Task.Factory.FromAsync<WebResponse>(
                                            continueWebRequest.BeginGetResponse,
                                            continueWebRequest.EndGetResponse,
                                            continueRequestAsyncState);

               return this.ProcessAsyncResponse<TResponse>(response as HttpWebResponse);
            }
            catch (Exception e)
            {
                this.HandleException(e);
                return default(TResponse);
            }
        }

        /// <summary>
        /// Processes the asynchronous response.
        /// </summary>
        /// <typeparam name="T">Response type.</typeparam>
        /// <param name="webResponse">The web response.</param>
        /// <returns>Task object.</returns>
        private T ProcessAsyncResponse<T>(HttpWebResponse webResponse)
        {
            using (webResponse)
            {
                if (webResponse.StatusCode == HttpStatusCode.OK ||
                    webResponse.StatusCode == HttpStatusCode.Accepted ||
                    webResponse.StatusCode == HttpStatusCode.Created)
                {
                    if (webResponse.ContentLength != 0)
                    {
                        using (var stream = webResponse.GetResponseStream())
                        {
                            if (stream != null)
                            {
                                return this.DeserializeServiceResponse<T>(stream);
                            }
                        }
                    }
                }
            }

            return default(T);
        }

        /// <summary>
        /// Set request content type.
        /// </summary>
        /// <param name="request">Web request object.</param>
        private void SetCommonHeaders(WebRequest request)
        {
            request.ContentType = "application/json";
        }

        /// <summary>
        /// Deserializes the service response.
        /// </summary>
        /// <typeparam name="T">The type of the response.</typeparam>
        /// <param name="stream">The stream.</param>
        /// <returns>Service response.</returns>
        private T DeserializeServiceResponse<T>(System.IO.Stream stream)
        {
            string message = string.Empty;
            using (StreamReader reader = new StreamReader(stream))
            {
                message = reader.ReadToEnd();
            }

            JsonSerializerSettings settings = new JsonSerializerSettings();
            settings.DateFormatHandling = DateFormatHandling.IsoDateFormat;
            settings.NullValueHandling = NullValueHandling.Ignore;
            settings.ContractResolver = this.defaultResolver;

            return JsonConvert.DeserializeObject<T>(message, settings);
        }

        /// <summary>
        /// Serialize the request body to byte array.
        /// </summary>
        /// <typeparam name="T">Type of request object.</typeparam>
        /// <param name="requestBody">Strong typed request object.</param>
        /// <returns>Byte array.</returns>
        private byte[] SerializeRequestBody<T>(T requestBody)
        {
            if (requestBody == null || requestBody is Stream)
            {
                return null;
            }
            else
            {
                JsonSerializerSettings settings = new JsonSerializerSettings();
                settings.DateFormatHandling = DateFormatHandling.IsoDateFormat;
                settings.ContractResolver = this.defaultResolver;

                return System.Text.Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(requestBody, settings));
            }
        }

        /// <summary>
        /// Process the exception happened on rest call.
        /// </summary>
        /// <param name="exception">Exception object.</param>
        private void HandleException(Exception exception)
        {
            WebException webException = exception as WebException;
            if (webException != null && webException.Response != null)
            {
                if (webException.Response.ContentType.ToLower().Contains("application/json"))
                {
                    Stream stream = null;

                    try
                    {
                        stream = webException.Response.GetResponseStream();
                        if (stream != null)
                        {
                            string errorObjectString;
                            using (StreamReader reader = new StreamReader(stream))
                            {
                                stream = null;
                                errorObjectString = reader.ReadToEnd();
                            }

                            ClientError errorCollection = JsonConvert.DeserializeObject<ClientError>(errorObjectString);
                            if (errorCollection != null)
                            {
                                throw new ClientException
                                {
                                    Error = errorCollection
                                };
                            }
                        }
                    }
                    finally
                    {
                        if (stream != null)
                        {
                            stream.Dispose();
                        }
                    }
                }
            }

            throw exception;
        }

        /// <summary>
        /// This class is used to pass on "state" between each Begin/End call
        /// It also carries the user supplied "state" object all the way till
        /// the end where is then hands off the state object to the
        /// WebRequestCallbackState object.
        /// </summary>
        internal class WebRequestAsyncState
        {
            /// <summary>
            /// Gets or sets request bytes of the request parameter for http post.
            /// </summary>
            public byte[] RequestBytes { get; set; }

            /// <summary>
            /// Gets or sets the HttpWebRequest object.
            /// </summary>
            public HttpWebRequest WebRequest { get; set; }

            /// <summary>
            /// Gets or sets the request state object.
            /// </summary>
            public object State { get; set; }
        }

        #endregion
    }
}