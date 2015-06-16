using System;
using System.IO;
using System.Linq;
using AzureMLClient.Contracts;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;

namespace AzureMLClient
{
    public static class Helper
    {
        public static AzureBlobDataReference UploadFileToBlob(string path)
        {
            using (var fileStream = System.IO.File.OpenRead(path))
            {
               return UploadFileToBlob(fileStream, path);
            }
        }

        public static AzureBlobDataReference UploadFileToBlob(Stream fileStream, string path)
        {
            var storageAccount = CloudStorageAccount.Parse(Configurations.AzureStorageConnectionString);
            var blobClient = storageAccount.CreateCloudBlobClient();
            // Retrieve a reference to a container. 
            var container = blobClient.GetContainerReference(Configurations.AzureStorageContainerName);
            // Create the container if it doesn't already exist.
            container.CreateIfNotExists();

            // set container to be accessible, optionall, the blob can be protected with a sas key
            container.SetPermissions(new BlobContainerPermissions { PublicAccess = BlobContainerPublicAccessType.Blob });
            var blobName = path.Split('\\').Last();
            var blob = container.GetBlockBlobReference(blobName);
            blob.UploadFromStream(fileStream);

            return new AzureBlobDataReference()
            {
                ConnectionString = Configurations.AzureStorageConnectionString,
                RelativeLocation = Configurations.AzureStorageContainerName + "/" + blobName
            };
        }
    }
}
