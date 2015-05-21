using MarketBasket.Core;
using MarketBasket.Web.Models;
using Microsoft.Data.OData;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.OData;

namespace MarketBasket.Web.Controllers
{
    // HACK: The DataMarket Explorer UI assumes that EntitySet names are the same as the EntityType
    [EntitySetAttribute(typeof(Model), "Model", GetAction = "List")]
    [ApiKeyAuthorizationAttribute("YOUR_SITE_SECRET")]
    public class FrequentlyBoughtTogetherController : ODataController, IUserScopedController
    {
        private ModelDataProvider modelProvider;
        private string defaultUserId = "public";
        private const string marketplaceUserHeaderName = "X-DM-AccountId";

        public FrequentlyBoughtTogetherController()
        {
            modelProvider = new ModelDataProvider();
        }

        [Description("Create a new Frequently Bought Together Model")]
        [ODataAction(ReturnType = typeof(ModelActionResult), IsSideEffecting = true)]
        public IHttpActionResult Create(
            [Description("Identifer to refer to the model")]
            [SampleValues("MyModel")]
            string Id,
            [Description("Minimum Number of Occurences a item needs to be seen to be considered frequent")]
            [SampleValues(30)]
            int MinumumOccurrences,
            [Description("Maximum Items in a Frequent Set")]
            [SampleValues(3)]
            [EnumValues(2, 3)]
            int MaxItemsSetSize)
        {
            Id = Id.Trim('\'');

            if (modelProvider.GetModel(UserId, Id) != null)
            {
                return Fail("A model with Id {0} already exists.", Id);
            }

            // Create the Model
            var model = modelProvider.CreateModel(UserId, Id, MinumumOccurrences, MaxItemsSetSize);

            return model != null ? Success("The model {0} was created succesfully", Id) : Fail("The model {0} was could not be created", Id);

        }

    

        [AcceptVerbs("POST")]
        [ODataAction(ReturnType = typeof(ModelActionResult), IsSideEffecting = true)]
        public async Task<IHttpActionResult> Upload(
            [Description("Id of the model to updata a data file to")]
            [SampleValues("MyModel")]
             string Id)
        {
            Id = Id.Trim('\'');
            
            var model = modelProvider.GetModel(UserId, Id);
            if (model == null)
            {
                return Fail("The model {0} does not exist", Id);
            }

            if (Request.Method.Method == "GET")
            {
                return Fail("You must perform an HTTP POST of the file to this url to upload a data file");
            }

            // get the request stream
            Stream requestStream;
            if (Request.Content.IsMimeMultipartContent())
            {
                // for multipart content return the first stream
                var streamProvider = await Request.Content.ReadAsMultipartAsync();
                var fileContent = streamProvider.Contents.FirstOrDefault(c => c is StreamContent);
                if (fileContent == null)
                {
                    return StatusCode(HttpStatusCode.BadRequest);
                }
                requestStream = await fileContent.ReadAsStreamAsync();
            }
            else
            {
                // otherwise just read the stream
                requestStream = await Request.Content.ReadAsStreamAsync();
            }

            // upload the data
            bool uploaded = modelProvider.WriteModelDataFile(UserId, Id, requestStream);

            return uploaded ? Success("The data file for model {0} was sucessfully uploaded", Id) : Fail("The data file for model {0} was failed to upload", Id);
        }


        [ODataAction(ReturnType = typeof(ModelActionResult), IsSideEffecting = true)]
        public IHttpActionResult Train(
            [Description("Id of the model to train")]
            [SampleValues("MyModel")]
            string Id)
        {
            Id = Id.Trim('\'');

            // Allow &force to be added to the url to bypass checking on modelstate
            bool force = Request.GetQueryNameValuePairs().Any(n => n.Key.ToLowerInvariant() == "force");

            var model = modelProvider.GetModel(UserId, Id);
            if (model == null)
            {
                return Fail("The model {0} does not exist.", Id);
            }
            if (string.IsNullOrEmpty(model.DataFileBlobName))
            {
                return Fail("The model {0} does not have any data. Upload training data before training the model.", Id);
            }
            if (!force && !model.TrainingInvalidated)
            {
                return Fail("The model {0} is Trained and does not require training.  Modify setting or upload new data to train the model", Id);
            }
            if (!force && model.IsTraining)
            {
                return Fail("The model {0} is currently being trained.", Id);
            }

            // kick off the model Builder
            ModelBuilder builder = new ModelBuilder(UserId, Id);
            bool started = builder.TrainModelAsync(force);

            return started ? Success("Training for model {0} has successfully started.", Id) : Fail("Training for model {0} failed to start.", Id);
        }

        [ODataAction(ReturnType = typeof(Prediction))]
        public IHttpActionResult Score(
            [Description("Id of the model to use for Prediction")]
            [SampleValues("MyModel")]
            string Id,
            [Description("Item that you want to recieve the Frequently Bought Set for")]
            [SampleValues("MyProductID")]
            string Item)
        {
            Id = Id.Trim('\'');
            Item = Item.Trim('\'');

            var model = modelProvider.GetModel(UserId, Id);
            if (model == null)
            {
                return NotFound();
            }

            // pass the marketplace headers along
            var headers = new [] { new KeyValuePair<string,string>(marketplaceUserHeaderName, UserId)};

            ModelBuilder builder = new ModelBuilder(UserId, Id);
            var itemSet = builder.ScoreModel(Item, headers);

            return Ok<Prediction>(itemSet);
        }


        [Route("odata/Models")]
        [ODataAction(ReturnType = typeof(IEnumerable<Model>))]
        public IHttpActionResult List()
        {
            var models = modelProvider.GetModels(UserId).Select(GetModelFromData);
            return Ok<IEnumerable<Model>>(models);
        }


        [Description("Gets the status of a model")]
        [ODataAction(ReturnType = typeof(IEnumerable<Model>))]
        public IHttpActionResult Get(
            [Description("Id of the model to use for Prediction")]
            [SampleValues("MyModel")]
            string Id)
        {
            Id = Id.Trim('\'');

            List<Model> models = new List<Model>();

            var model = modelProvider.GetModel(UserId, Id);
            if (model != null)
            {
                models.Add(GetModelFromData(model));
            }

            return Ok<IEnumerable<Model>>(models);
        }

        [ODataAction(ReturnType = typeof(ModelActionResult), IsSideEffecting = true)]
        public IHttpActionResult Update(
            [Description("Id of the model to update")]
            [SampleValues("MyModel")]
            string Id,
            [Description("Minimum Number of Occurences a item needs to be seen to be considered frequent")]
            [SampleValues(30)]
            int MinumumOccurrences,
            [Description("Maximum Items in a Frequent Set")]
            [SampleValues(3)]
            [EnumValues(2, 3)]
            int MaxItemsSetSize)
        {
            Id = Id.Trim('\'');

            var model = modelProvider.GetModel(UserId, Id);
            if (model == null)
            {
                return Fail("The model {0} does not exsist.", Id);
            }

            model.SupportThreshhold = MinumumOccurrences;
            model.MaxItemSetSize = MaxItemsSetSize;
            model.TrainingInvalidated = true;
            bool updated = modelProvider.UpdateModel(model);

            return updated ? Success("Model {0} was updated succesfully", Id) : Fail("Model {0} could not be updated", Id);
        }


        [ODataAction(ReturnType = typeof(ModelActionResult), IsSideEffecting = true)]
        public IHttpActionResult Delete(
            [Description("Id of the model to delete")]
            [SampleValues("MyModel")]
            string Id)
        {
            Id = Id.Trim('\'');

            var model = modelProvider.GetModel(UserId, Id);
            if (model == null)
            {
                return Fail("The model {0} does not exsist.", Id);
            }

            // unpublish the webservice
            ModelBuilder modelManager = new ModelBuilder(UserId, Id);
           // modelManager.RemoveWebserviceIfPublished(model);

            // delete the data
            bool deleted = modelProvider.DeleteModel(UserId, Id);

            return deleted ? Success("Model {0} was deleted succesfully", Id) : Fail("Model {0} could not be deleted", Id);
        }

        private IHttpActionResult Success(string message, params object[] args)
        {
            return Ok<ModelActionResult>(new ModelActionResult() { Success = true, Message = string.Format(message, args) });
        }

        private IHttpActionResult Fail(string message, params object[] args)
        {
            return Ok<ModelActionResult>(new ModelActionResult() { Success = false, Message = string.Format(message, args) });
        }

        public string UserId
        {
            get
            {
                if (Request.Headers.Contains(marketplaceUserHeaderName))
                {
                    return Request.Headers.GetValues(marketplaceUserHeaderName).First();
                }
                return defaultUserId;
            }
            set { defaultUserId = value; }
        }

        private Model GetModelFromData(ModelData model)
        {
            return new Model()
            {
                Name = model.RowKey,
                Status = model.Status,
                MaxItemsSetSize = model.MaxItemSetSize,
                MinumumOccurrences = model.SupportThreshhold,
                ReadyForScoring = !string.IsNullOrEmpty(model.ScoringUrl),
                HasData = !string.IsNullOrEmpty(model.DataFileBlobName),
                NeedsTraining = model.TrainingInvalidated,
                IsTraining = model.IsTraining,
                DataUploadTime = model.DataUploadTime,
                TrainingStartTime = model.TrainingStartTime,
                TrainingEndTime = model.TrainingEndTime
            };
        }
    }
}
