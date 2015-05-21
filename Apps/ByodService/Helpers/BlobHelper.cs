using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.WindowsAzure.Storage.RetryPolicies;
using System.Configuration;

namespace Microsoft.Sage.Cloud.Infra.Storage
{
    /// <summary>
    /// Wrap Azure Blob Storage Access
    /// </summary>
    public class BlobHelper
    {
        /// <summary>
        /// Constructor
        /// </summary>
        public BlobHelper()
        {
            this._account = CloudStorageAccount.Parse(ConfigurationManager.ConnectionStrings["DataConnectionString"].ConnectionString);
            this._blobClient = _account.CreateCloudBlobClient();
            LinearRetry linearRetry = new LinearRetry(TimeSpan.FromMilliseconds(500), 3);
            this._blobClient.RetryPolicy = linearRetry;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="containerName">container name to be used for container operations</param>
        public BlobHelper(string containerName) : this()
        {
            // creating container reference
            this._container = _blobClient.GetContainerReference(containerName);
        }

        /// <summary>
        /// Enumerate the containers in a storage account.
        /// </summary>
        /// <returns>the list of containers</returns> 
        public IEnumerable<CloudBlobContainer> ListContainers()
        {
            try
            {
                return _blobClient.ListContainers();
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return null;
                }

                throw;
            }
        }

        /// <summary>
        /// Create a blob container
        /// </summary>
        /// <param name="containerName">the name of the container</param>
        public void CreateContainer(string containerName)
        {
            CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
            container.CreateIfNotExists();
        }

        /// <summary>
        /// Delete a blob container
        /// </summary>
        /// <param name="containerName">the container name</param>
        /// <returns>Return true on success, false if not found, throw exception on error.</returns>
        public bool DeleteContainer(string containerName)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                container.Delete();
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get container access control
        /// </summary>
        /// <param name="containerName">the name of the container</param>
        /// <param name="accessLevel">Access level set to container|blob|private</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GetContainerACL(string containerName, out BlobContainerPublicAccessType accessLevel)
        {
            accessLevel = BlobContainerPublicAccessType.Off;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                BlobContainerPermissions permissions = container.GetPermissions();
                accessLevel = permissions.PublicAccess;
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Set container access control to container|blob|private
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="accessLevel">Set access level to container|blob|private</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool SetContainerACL(string containerName, BlobContainerPublicAccessType accessLevel)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                BlobContainerPermissions permissions = new BlobContainerPermissions {PublicAccess = accessLevel};
                container.SetPermissions(permissions);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get container access policies
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="policies">container policies</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GetContainerAccessPolicy(string containerName, out SortedList<string, SharedAccessBlobPolicy> policies)
        {
            policies = new SortedList<string, SharedAccessBlobPolicy>();

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                BlobContainerPermissions permissions = container.GetPermissions();

                if (permissions.SharedAccessPolicies != null)
                {
                    foreach (KeyValuePair<string, SharedAccessBlobPolicy> policy in permissions.SharedAccessPolicies)
                    {
                        policies.Add(policy.Key, policy.Value);
                    }
                }

                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Set container access policy
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="policies">container policies</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool SetContainerAccessPolicy(string containerName, SortedList<string, SharedAccessBlobPolicy> policies)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                BlobContainerPermissions permissions = container.GetPermissions();

                permissions.SharedAccessPolicies.Clear();

                if (policies != null)
                {
                    foreach (KeyValuePair<string, SharedAccessBlobPolicy> policy in policies)
                    {
                        permissions.SharedAccessPolicies.Add(policy.Key, policy.Value);
                    }
                }

                container.SetPermissions(permissions);

                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Generate a shared access signature for a policy
        /// </summary>
        /// <param name="containerName"></param>
        /// <param name="policy"></param>
        /// <param name="signature"></param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GenerateSharedAccessSignature(string containerName, SharedAccessBlobPolicy policy, out string signature)
        {
            signature = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                signature = container.GetSharedAccessSignature(policy);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }
        /// <summary>
        /// Generate a shared access signature for a blob and returns the URL
        /// </summary>
        /// <param name="containerName"></param>
        /// <param name="blobName"></param>
        /// <param name="accessDuration"></param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public string GenerateTemporaryBlobReadUrl(string containerName, string blobName, TimeSpan accessDuration)
        {
            var policy = new SharedAccessBlobPolicy
            {
                Permissions = SharedAccessBlobPermissions.Read,
                SharedAccessExpiryTime = DateTimeOffset.Now + accessDuration
            };

            CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
            var blob = container.GetBlockBlobReference(blobName);
            var signature = blob.GetSharedAccessSignature(policy);
            return blob.Uri + signature;
        }


        /// <summary>
        /// Generate a shared access signature for a saved container policy
        /// </summary>
        /// <param name="containerName"></param>
        /// <param name="policyName"></param>
        /// <param name="signature"></param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GenerateSharedAccessSignature(string containerName, string policyName, out string signature)
        {
            signature = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                signature = container.GetSharedAccessSignature(new SharedAccessBlobPolicy(), policyName);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get container properties
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="properties">container properties</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GetContainerProperties(string containerName, out BlobContainerProperties properties)
        {
            properties = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                container.FetchAttributes();
                properties = container.Properties;
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get container metadata
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="metadata">container meta data</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GetContainerMetadata(string containerName, out IDictionary<string, string> metadata)
        {
            metadata = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                container.FetchAttributes();
                metadata = container.Metadata;
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Set container metadata
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="metadata">container meta data</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool SetContainerMetadata(string containerName, IEnumerable<KeyValuePair<string,string>> metadata)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                container.Metadata.Clear();
                foreach (var keyValuePair in metadata)
                {
                    container.Metadata.Add(keyValuePair);
                }
                container.SetMetadata();
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Enumerate the blobs in a container
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobList">out - the blobs, you should check the type and
        /// cast accordingly to CloudBlockBlob or CloudPageBlob</param>
        /// <param name="prefix"> blobs to list name prefix, no prefix if null</param>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool ListBlobs(string containerName, out IEnumerable<IListBlobItem> blobList, string prefix = null)
        {
            blobList = new List<IListBlobItem>();

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                
                //List blobs in this container using a flat listing.
                blobList = container.ListBlobs(prefix, true);
                // we call count to force the method to execute the listblobs
                // since it is done lazly and then we will get expcetion in 
                // unexpected location
                blobList.Count();

                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Queries for a specific blob-name inside a blob container
        /// </summary>
        /// <returns>True if found, false if not fount and throws on exception</returns>
        public bool IsExist(string containerName, string blobName)
        {
            IEnumerable<IListBlobItem> blobList;
            if (!ListBlobs(containerName, out blobList))
            {
                return false;
            }
            return blobList.Any(cloudBlob => ((ICloudBlob)cloudBlob).Name.Equals(blobName));
        }

        /// <summary>
        /// Get a stream that enables to write into a block blob.
        /// If the blob already exists it will be overwritten.
        /// </summary>
        /// <param name="containerName">the container name</param>
        /// <param name="blobName">the blob name</param>
        /// <returns>the Stream that enables to write data into the blob</returns>
        public Stream GetBlockBlobWriter(string containerName, string blobName)
        {
            CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
            CloudBlockBlob blockBlobReference = container.GetBlockBlobReference(blobName);
            BlobRequestOptions opt = new BlobRequestOptions { MaximumExecutionTime = GetDataTimeout };
            return blockBlobReference.OpenWrite(null, opt);
        }

        /// <summary>
        /// Get a Stream that enables to read from a blob
        /// </summary>
        /// <param name="containerName">the container name</param>
        /// <param name="blobName">the blob name</param>
        /// <returns>the BlobStream that enables to read data from the blob</returns>
        public Stream GetBlobReader(string containerName, string blobName)
        {
            if (!this.IsExist(containerName, blobName)) return null;
            CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
            ICloudBlob blobReferenceFromServer = container.GetBlobReferenceFromServer(blobName);
            BlobRequestOptions opt = new BlobRequestOptions { MaximumExecutionTime = GetDataTimeout };
            return blobReferenceFromServer.OpenRead(null, opt);
        }

        /// <summary>
        /// Put (create or update) a block blob
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobName">blob name</param>
        /// <param name="content">string content</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool PutBlockBlob(string containerName, string blobName, string content)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudBlockBlob blob = container.GetBlockBlobReference(blobName);
                MemoryStream ms = new MemoryStream(Convert(content));
                blob.UploadFromStream(ms);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Put (create or update) a block blob
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobName">blob name</param>
        /// <param name="content">string content</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public async Task<bool> PutBlockBlobAsync(string containerName, string blobName, string content)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudBlockBlob blob = container.GetBlockBlobReference(blobName);
                var futureRes = blob.BeginUploadFromStream(new MemoryStream(Convert(content)), null, null);
                return await Task.Factory.FromAsync(futureRes, res =>
                {
                    blob.EndUploadFromStream(res);
                    return true;
                });
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode== 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Put (create or update) a block blob
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobName">blob name</param>
        /// <param name="stream">a stream</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool PutBlockBlob(string containerName, string blobName, Stream stream)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudBlockBlob blob = container.GetBlockBlobReference(blobName);
                blob.UploadFromStream(stream);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Put (create or update) a block blob
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobName">blob name</param>
        /// <param name="stream">a stream</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public async Task<bool> PutBlockBlobAsync(string containerName, string blobName, Stream stream)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudBlockBlob blob = container.GetBlockBlobReference(blobName);
                var futureRes = blob.BeginUploadFromStream(stream, null, null);
                return await Task.Factory.FromAsync(futureRes, res =>
                {
                    blob.EndUploadFromStream(res);
                    return true;
                });
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Put a block blob in the container created in the constructor
        /// </summary>
        /// <param name="blobName">blob name</param>
        /// <param name="data">a stream</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public async Task<bool> PutBlockBlobAsync(string blobName, Stream data)
        {
            try
            {
                if (_container == null)
                    return false;

                CloudBlockBlob blob = this._container.GetBlockBlobReference(blobName);
                var futureRes = blob.BeginUploadFromStream(data, null, null);
                return await Task.Factory.FromAsync(futureRes, res =>
                {
                    blob.EndUploadFromStream(res);
                    return true;
                });
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Put (create or update) a page blob.
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobName">blob name</param>
        /// <param name="pageBlobSize">The maximum size of the blob, in bytes. This value must be a multiple of 512 (size of a page)</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error.</returns>
        public bool PutPageBlob(string containerName, string blobName, int pageBlobSize)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudPageBlob blob = container.GetPageBlobReference(blobName);
                blob.Create(pageBlobSize);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Put a page of a page blob.
        /// </summary>
        /// <param name="containerName">container name</param>
        /// <param name="blobName">blob name</param>
        /// <param name="content">page content, MUST be aligned with the 512 byte bounderies</param>
        /// <param name="pageOffset">page offset, must be a mutiplication of 512</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error.</returns>
        public bool PutPage(string containerName, string blobName, byte[] content, long pageOffset)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudPageBlob blob = container.GetPageBlobReference(blobName);
                MemoryStream stream = new MemoryStream(content);
                blob.WritePages(stream, pageOffset);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get for a Page Blob the page ranges
        /// </summary>
        /// <param name="containerName">the container name</param>
        /// <param name="blobName">the blob name</param>
        /// <param name="pageRanges">OUT - enumeration of page ranges</param>
        /// <returns>Return true on success, false if unable to create, throw exception on error.</returns>
        public bool GetPageRanges(string containerName, string blobName, out IEnumerable<PageRange> pageRanges)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudPageBlob blob = container.GetPageBlobReference(blobName);
                pageRanges = blob.GetPageRanges();
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    pageRanges = null; 
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// gets the size of a page blob (it is up to the caller to make sure that the name matches a page blob)
        /// </summary>
        /// <param name="containerName">the container name</param>
        /// <param name="blobName">the blob name</param>
        /// <returns>the size of the page blob. throws <see cref="DataHandlerException"/> if fails. </returns>
        public long GetPageBlobSize(string containerName, string blobName)
        {
            IEnumerable<PageRange> ranges;
            if (!this.GetPageRanges(containerName, blobName, out ranges))
                throw new ApplicationException(string.Format("Failed to put blob {0} in container {1}", blobName, containerName));
            return 0 == ranges.Count() ? 0 : ranges.Last().EndOffset + 1;
        }

        /// <summary>
        /// Get (retrieve) a blob and return its content
        /// </summary>
        /// <param name="containerName"></param>
        /// <param name="blobName"></param>
        /// <param name="content"></param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool GetBlob(string containerName, string blobName, out string content)
        {
            content = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                MemoryStream ms = new MemoryStream();
                blob.DownloadToStream(ms);
                byte[] array = ms.ToArray();
                content = Convert(array);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Read a blob data into the given stream
        /// </summary>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool GetBlob(string containerName, string blobName, Stream content)
        {
            try
            {
                BlobRequestOptions opt = new BlobRequestOptions { MaximumExecutionTime = GetDataTimeout };
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                blob.DownloadToStream(content, null, opt);
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Read a blob data into the given stream
        /// </summary>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public async Task<bool> GetBlobAsync(string containerName, string blobName, Stream content)
        {
            try
            {
                BlobRequestOptions opt = new BlobRequestOptions { MaximumExecutionTime = GetDataTimeout };
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                var futureRes = blob.BeginDownloadToStream(content, null, opt);
                return await Task.Factory.FromAsync(futureRes, res =>
                {
                    blob.EndDownloadToStream(res);
                    return true;
                });
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        public async Task<byte[]> GetBlobAsync(string containerName, string blobName)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                var target = new MemoryStream();
                var futureRes = blob.BeginDownloadToStream(target, null, null);
                return await Task.Factory.FromAsync(futureRes, res =>
                {
                    blob.EndDownloadToStream(res);
                    byte[] array = target.ToArray();
                    return array;
                });
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return null;
                }

                throw;
            }
        }

        /// <summary>
        /// Get (retrieve) a block blob and return its content
        /// </summary>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool GetBlob(string containerName, string blobName, out byte[] content)
        {
            content = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                BlobRequestOptions opt = new BlobRequestOptions { MaximumExecutionTime = GetDataTimeout };
                MemoryStream ms = new MemoryStream();
                blob.DownloadToStream(ms, null, opt);
                if (ms.Length == 0) return false;
                content = ms.ToArray();
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get the size of a blob
        /// </summary>
        public long GetBlobSize(string containerName, string blobName)
        {
            BlobProperties props;
            return !GetBlobProperties(containerName, blobName, out props) ? 0 : props.Length;
        }

        /// <summary>
        /// Create a snapshot of a block blob. A snapshot is a copy of the blob for the moment it is created. It
        /// is a read only object.
        /// </summary>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool SnapshotBlockBlob(string containerName, string blobName, Stream stream)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                CloudBlockBlob blob = container.GetBlockBlobReference(blobName);
                CloudBlockBlob cloudBlob = blob.CreateSnapshot();
                cloudBlob.DownloadToStream(stream);

                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Delete a blob
        /// </summary>
        /// <param name="containerName"></param>
        /// <param name="blobName"></param>
        /// <returns>Return true on success, false if unable to create, throw exception on error</returns>
        public bool DeleteBlob(string containerName, string blobName)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blobReferenceFromServer = container.GetBlobReferenceFromServer(blobName);
                blobReferenceFromServer.DeleteIfExists();
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        public async Task<bool> DeleteBlobAsync(string containerName, string blobName)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                var futureRes = blob.BeginDelete(null, null);
                var retVal = 
                    await Task.Factory.FromAsync(futureRes, res =>
                    {
                        try
                        {
                            blob.EndDelete(res);
                            return true;
                        }
                        catch (StorageException ex)
                        {
                            if (ex.RequestInformation.HttpStatusCode == 404)
                            {
                                return false;
                            }
                            throw;
                        }
                    });

                return retVal;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get blob metadata
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GetBlobMetadata(string containerName, string blobName, out IDictionary<string, string> metadata)
        {
            metadata = null;

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                blob.FetchAttributes();

                metadata = blob.Metadata;
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        public async Task<IDictionary<string, string>> GetBlobMetadataAsync(string containerName, string blobName)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                var futureRes = blob.BeginFetchAttributes(null, null);
                return await Task.Factory.FromAsync(futureRes, res =>
                {
                    blob.EndFetchAttributes(res);
                    return blob.Metadata;
                });
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return null;
                }

                throw;
            }
        }

        /// <summary>
        /// Set blob metadata
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool SetBlobMetadata(string containerName, string blobName, IEnumerable<KeyValuePair<string,string>> metadata)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                blob.Metadata.Clear();
                foreach (var keyValuePair in metadata)
                {
                    blob.Metadata.Add(keyValuePair);
                }
                blob.SetMetadata();
                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Set the properties of for the blob. Using null for a property means that the original property ofthe blob 
        /// remain unaffected, using empty string mean to "erase" the original property value
        /// Note that only 
        /// <list type="number">
        /// <item>CacheControl</item>
        /// <item>ContentEncoding</item>
        /// <item>ContentLanguage</item>
        /// <item>ContentMD5</item>
        /// <item>ContentType</item>
        /// </list>
        /// </summary>
        /// <param name="containerName"></param>
        /// <param name="blobName"></param>
        /// <param name="properties"></param>
        /// <returns></returns>
        public bool SetBlobProperties(string containerName, string blobName, BlobProperties properties)
        {
            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                blob.FetchAttributes();
                //update the properties with new values if exist or use the original ones.
                blob.Properties.CacheControl = properties.CacheControl ?? blob.Properties.CacheControl;
                blob.Properties.ContentEncoding= properties.ContentEncoding ?? blob.Properties.ContentEncoding;
                blob.Properties.ContentLanguage= properties.ContentLanguage ?? blob.Properties.ContentLanguage;
                blob.Properties.ContentMD5 = properties.ContentMD5 ?? blob.Properties.ContentMD5;
                blob.Properties.ContentType = properties.ContentType ?? blob.Properties.ContentType;
 
                blob.SetProperties();

                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// Get blob properties
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool GetBlobProperties(string containerName, string blobName, out BlobProperties properties)
        {
            properties = null; 

            try
            {
                CloudBlobContainer container = _blobClient.GetContainerReference(containerName);
                ICloudBlob blob = container.GetBlobReferenceFromServer(blobName);
                blob.FetchAttributes();
                properties = blob.Properties;

                return true;
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
        }

        /// <summary>
        /// returns the blob name from IListBlobItem
        /// </summary>
        public static string GetBlobName(IListBlobItem blobItem)
        {
            string blobName = string.Empty;
            if (blobItem is CloudBlockBlob)
            {
                blobName = ((CloudBlockBlob)blobItem).Name;
            }
            else if (blobItem is CloudPageBlob)
            {
                blobName = ((CloudPageBlob)blobItem).Name;
            }   
            else if (blobItem is CloudBlobDirectory)
            {
                blobName = ((CloudBlobDirectory) blobItem).Uri.ToString();
            }
            return blobName;
        }

        /// <summary>
        /// Convert string into byte[]
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        private static byte[] Convert(string str)
        {
            System.Text.UTF8Encoding encoding = new System.Text.UTF8Encoding();
            return encoding.GetBytes(str);
        }

        /// <summary>
        /// Convert byte[] into string
        /// </summary>
        /// <returns></returns>
        private static string Convert(byte[] buffer)
        {
            System.Text.UTF8Encoding encoding = new System.Text.UTF8Encoding();
            return encoding.GetString(buffer);
        }

        /// <summary>
        /// Get Blob data connection timeout
        /// </summary>
        private static readonly TimeSpan GetDataTimeout = new TimeSpan(1, 0, 0); // 1H

        /// <summary>
        /// Container reference for operations on same container
        /// </summary>
        private readonly CloudBlobContainer _container;

        /// <summary>
        /// Hold reference to the storage account
        /// </summary>
        private readonly CloudStorageAccount _account;

        /// <summary>
        /// Holds the storage client
        /// </summary>
        private readonly CloudBlobClient _blobClient;
    }
}
