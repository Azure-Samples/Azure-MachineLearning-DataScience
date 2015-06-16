using Microsoft.Sage.Cloud.Infra.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.IO;

namespace MarketBasket.Core
{
    public class ModelDataProvider
    {
        private TableHelper tableClient = new TableHelper();
        private BlobHelper blobClient = new BlobHelper();
        
        public static readonly string ModelTableName = "Models";
        public static readonly string ModelBlobContainerName = "modelfiles";
        
        public IEnumerable<ModelData> GetModels(string userId)
        {
            return tableClient.GetAllEntitiesByPartition<ModelData>(ModelTableName, userId);
        }

        public ModelData GetModel(string userId, string name)
        {
            return tableClient.GetEntityByPartitionAndRow<ModelData>(ModelTableName, userId, name);
        }

        public ModelData CreateModel(string userId, string name, int supportThreshhold, int maxItemSetSize)
        {
            // Create a new model
            var model = new ModelData()
            {
                PartitionKey = userId,
                RowKey = name,
                MaxItemSetSize = maxItemSetSize,
                SupportThreshhold = supportThreshhold,
                Status = "No Training Data"
            };
            
            // insert the entity and return it if successfull 
            return tableClient.InsertEntity(ModelTableName, model) ? model : null;
        }

        public bool UpdateModel(ModelData model)
        {
            // insert the entity and return it if successfull 
            return tableClient.UpdateEntity(ModelTableName, model);
        }

        public bool DeleteModel(string userId, string name)
        {
            var model = GetModel(userId, name);
            if (model != null)
            {
                if (!string.IsNullOrEmpty(model.DataFileBlobName))
                {
                    blobClient.DeleteBlob(ModelBlobContainerName, model.DataFileBlobName);
                }

                // delete the table entry
                return tableClient.DeleteEntity(ModelTableName, userId, name);
            }
            return false;
        }


        public Stream ReadModelDataFile(string userId, string name)
        {
            var model = GetModel(userId, name);
            if (model != null && model.DataFileBlobName != null)
            {
                return blobClient.GetBlobReader(ModelBlobContainerName, model.DataFileBlobName);
            }
            return null;
        }

        public Stream ReadBlob(string blobName)
        {

            return blobClient.GetBlobReader(ModelBlobContainerName, blobName);
        }

        public string GetTemporaryDataFileReadUrl(string blobName, TimeSpan readDuration)
        {
            return blobClient.GenerateTemporaryBlobReadUrl(ModelBlobContainerName, blobName, readDuration);
        }


        public bool WriteModelDataFile(string userId, string name, Stream stream)
        {
            // get the model
            var model = GetModel(userId, name);
            if (model == null)
            {
                return false;
            }

            // Use the existing blob or create a new one
            var blobName = model.DataFileBlobName ?? userId + "/" + Guid.NewGuid() + ".csv";
            
            // upload the blob
            bool updated = blobClient.PutBlockBlob(ModelBlobContainerName, blobName, stream);

            // update the model status
            if (updated)
            {
                model.Status = "Data is Upload";
                model.TrainingInvalidated = true;
                model.DataFileBlobName = blobName;
                model.DataUploadTime = DateTimeOffset.Now;
                return tableClient.InsertOrMergeEntity(ModelTableName, model);
            }

            return updated;
        }
    }
}
