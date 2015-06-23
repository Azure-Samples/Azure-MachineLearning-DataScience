using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.RetryPolicies;
using Microsoft.WindowsAzure.Storage.Table;
using System.Configuration;

namespace Microsoft.Sage.Cloud.Infra.Storage
{
    /// <summary>
    /// Wrap Azure table storage access
    /// </summary>
    public class TableHelper
    {
        /// <summary>
        /// Constructor
        /// </summary>
        public TableHelper()
        {
            this._account = CloudStorageAccount.Parse(ConfigurationManager.ConnectionStrings["DataConnectionString"].ConnectionString);
            this._tableClient = _account.CreateCloudTableClient();
            LinearRetry linearRetry = new LinearRetry(TimeSpan.FromMilliseconds(500), 3);
            this._tableClient.RetryPolicy = linearRetry;
        }

        /// <summary>
        /// List Tables
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool ListTables(out IEnumerable<CloudTable> tableList)
        {
            tableList = new List<CloudTable>();

            try
            {
                tableList = _tableClient.ListTables();
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
        /// Create Table if not exists
        /// </summary>
        /// <param name="tableName">table name</param>
        public void CreateTable(string tableName)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            tableReference.CreateIfNotExists();
        }

        /// <summary>
        /// Delete Table if exists
        /// </summary>
        /// <param name="tableName">table name</param>
        public void DeleteTable(string tableName)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            tableReference.DeleteIfExists();
        }

        /// <summary>
        /// Insert entity, if entity already exists and exception will be thrown
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool InsertEntity(string tableName, ITableEntity entity)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation insertOperation = TableOperation.Insert(entity);
            TableResult tableResult = tableReference.Execute(insertOperation);
            return tableResult.HttpStatusCode == 204;
        }

        /// <summary>
        /// Insert the entity if new or replace if already exists.
        /// </summary>
        /// <returns>Return true on success, false if failed, throw exception on error</returns>
        public bool InsertOrUpdateEntity(string tableName, ITableEntity entity)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation insertOrReplace = TableOperation.InsertOrReplace(entity);
            TableResult tableResult = tableReference.Execute(insertOrReplace);
            return tableResult.HttpStatusCode == 204;
        }

        /// <summary>
        /// Insert the entity if new or merge if already exists.
        /// </summary>
        /// <returns>Return true on success, false if failed, throw exception on error</returns>
        public bool InsertOrMergeEntity(string tableName, ITableEntity entity)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation insertOrReplace = TableOperation.InsertOrMerge(entity);
            TableResult tableResult = tableReference.Execute(insertOrReplace);
            return tableResult.HttpStatusCode == 204;
        }

        /// <summary>
        /// Update an entity by Partition and Row keys
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool UpdateEntity(string tableName, ITableEntity entity)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation retrieve = TableOperation.Retrieve(entity.PartitionKey, entity.RowKey);
            TableResult retrieveResult = tableReference.Execute(retrieve);
            ITableEntity entityToUpdate = retrieveResult.Result as ITableEntity;
            if (null != entityToUpdate)
            {
                TableOperation replace = TableOperation.Replace(entity);
                TableResult replaceResult = tableReference.Execute(replace);
                return replaceResult.HttpStatusCode == 204;
            }
            return false;
        }

        /// <summary>
        /// Retrieve an entities by applying the table query and resolver
        /// </summary>
        public IEnumerable<T> GetEntity<T>(string tableName, TableQuery<DynamicTableEntity> tableQuery, EntityResolver<T> resolver)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            return tableReference.ExecuteQuery(tableQuery, resolver);
        }

        /// <summary>
        /// Retrieve an entity
        /// </summary>
        /// <returns>return the entity or null if does not exists</returns>
        public ITableEntity GetEntityByPartitionAndRow(string tableName, string partitionKey, string rowKey)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation retrieve = TableOperation.Retrieve(partitionKey, rowKey);
            TableResult retrieveResult = tableReference.Execute(retrieve);
            return retrieveResult.Result as ITableEntity;
        }

        /// <summary>
        /// Retrieve an entity
        /// </summary>
        /// <returns>return the entity or null if does not exists</returns>
        public T GetEntityByPartitionAndRow<T>(string tableName, string partitionKey, string rowKey, EntityResolver<T> resolver) where T : TableEntity
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation retrieve = TableOperation.Retrieve(partitionKey, rowKey, resolver);
            TableResult retrieveResult = tableReference.Execute(retrieve);
            object result = retrieveResult.Result;
            return result as T;
        }

        /// <summary>
        /// Retrieve an entity
        /// </summary>
        /// <returns>return the entity or null if does not exists</returns>
        public T GetEntityByPartitionAndRow<T>(string tableName, string partitionKey, string rowKey) where T : TableEntity
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation retrieve = TableOperation.Retrieve<T>(partitionKey, rowKey);
            TableResult retrieveResult = tableReference.Execute(retrieve);
            object result = retrieveResult.Result;
            return result as T;
        }



        /// <summary>
        /// Retrieve all entities by partition key
        /// </summary>
        public IEnumerable<DynamicTableEntity> GetAllEntitiesByPartition(string tableName, string partitionKey)
        {            
            TableQuery query = new TableQuery().Where(TableQuery.GenerateFilterCondition("PartitionKey", QueryComparisons.Equal, partitionKey));
            return ExecuteQuery(tableName, query);
        }

        /// <summary>
        /// Retrieve all entities by partition key
        /// </summary>
        public IEnumerable<T> GetAllEntitiesByPartition<T>(string tableName, string partitionKey) where T : TableEntity, new()
        {
            TableQuery<T> query = new TableQuery<T>().Where(TableQuery.GenerateFilterCondition("PartitionKey", QueryComparisons.Equal, partitionKey));
            return ExecuteQuery(tableName, query);
        }




        /// <summary>
        /// Execute a query on a table
        /// </summary>
        /// <returns>
        /// An enumerable collection of <see cref="T:Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity"/> objects, representing table entities returned by the query.
        /// </returns>
        public T ExecuteOperation<T>(string tableName, TableOperation operation)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableResult result= tableReference.Execute(operation);
            if (result != null)
            {
                return (T)result.Result;
            }
            return default(T);
        }

        /// <summary>
        /// Execute a query on a table
        /// </summary>
        /// <returns>
        /// An enumerable collection of <see cref="T:Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity"/> objects, representing table entities returned by the query.
        /// </returns>
        public IEnumerable<DynamicTableEntity> ExecuteQuery(string tableName, TableQuery query)
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            return tableReference.ExecuteQuery(query);       
        }
        
        /// <summary>
        /// Execute a query on a table
        /// </summary>
        /// <returns>
        /// An enumerable collection of <see cref="T:Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity"/> objects, representing table entities returned by the query.
        /// </returns>
        public IEnumerable<T> ExecuteQuery<T>(string tableName, TableQuery<T> query) where T : ITableEntity, new()
        {
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            return tableReference.ExecuteQuery(query);
        }
        /// <summary>
        /// Delete Entity by partition and key
        /// </summary>
        /// <returns>Return true on success, false if not found, throw exception on error</returns>
        public bool DeleteEntity(string tableName, string partitionKey, string rowKey)
        {
            ITableEntity entityToDelete = this.GetEntityByPartitionAndRow(tableName, partitionKey, rowKey);
            if (null == entityToDelete) return false;
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            TableOperation delete = TableOperation.Delete(entityToDelete);
            TableResult tableResult;
            try
            {
                tableResult = tableReference.Execute(delete);
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
            return tableResult.HttpStatusCode == 204;
        }


        /// <summary>
        /// Execute a batch on the table. 
        /// </summary>
        /// <returns>Return true on success, false if one of the operation failed</returns>
        public bool ExecuteBatch(string tableName, TableBatchOperation batch)
        {
            
            CloudTable tableReference = _tableClient.GetTableReference(tableName);
            
            IList<TableResult> tableResults;
            try
            {
                tableResults = tableReference.ExecuteBatch(batch);
            }
            catch (StorageException ex)
            {
                if (ex.RequestInformation.HttpStatusCode == 404)
                {
                    return false;
                }

                throw;
            }
            return tableResults.Any(res => res.HttpStatusCode != 204);
        }
        
        /// <summary>
        /// Retreives entities from a table in Azure storage filtered by time.
        /// Assumes that the PartitionKey column contains a timestamp expressed as ticks.
        /// </summary>
        /// <param name="tableName">table name</param>
        /// <param name="startTime">start time</param>
        /// <param name="endTime">end time</param>
        /// <param name="resolver">a delegate for resolving entities</param>
        /// <param name="columns">requested columns (optional), if omitted or null => all columns will be returned</param>
        public IEnumerable<T> GetEntitiesByTime<T>(string tableName, DateTime startTime, DateTime endTime, EntityResolver<T> resolver, string[] columns = null)
        {
            // define the query to retrieve the entities
            string filter = GetDurationFilter(startTime, endTime);
            TableQuery<DynamicTableEntity> query = new TableQuery<DynamicTableEntity>().Where(filter);
            if (columns != null) // select specific columns
            {
                query = query.Select(columns);
            }
            // execute the query
            return GetEntity(tableName, query, resolver);
        }

        /// <summary>
        /// Creates a query filter for the requested duration
        /// Assumes that the PartitionKey column contains a timestamp expressed as ticks.
        /// </summary>
        /// <param name="startTime">start time</param>
        /// <param name="endTime">end time</param>
        public static string GetDurationFilter(DateTime startTime, DateTime endTime)
        {
            var timeSpan = endTime.Subtract(startTime);
            if (timeSpan.TotalMinutes < 1)
            {
                throw new ArgumentException("End time must be larger than start time");
            }

            string filterStartTime = TableQuery.GenerateFilterCondition(PartitionKeyStr, QueryComparisons.GreaterThanOrEqual, "0" + startTime.Ticks);
            string filterEndTime = TableQuery.GenerateFilterCondition(PartitionKeyStr, QueryComparisons.LessThanOrEqual, "0" + endTime.Ticks);
            return TableQuery.CombineFilters(filterStartTime, TableOperators.And, filterEndTime);
        }



        /// <summary>
        /// Completes query for right azure table timestamps syntax Timestamp ge datetime'2014-01-10T00:00:00Z'
        /// </summary>
        /// <param name="timestampQuery"></param>
        /// <returns></returns>
        private static string CompleteQuery(string timestampQuery)
        {
            int index = timestampQuery.IndexOf("'", System.StringComparison.Ordinal);
            if (index != -1)
            {
                timestampQuery = timestampQuery.Insert(index, DatetimeStr);
                int lastIndex = timestampQuery.LastIndexOf("'", System.StringComparison.Ordinal);
                if (lastIndex != -1)
                {
                    timestampQuery = timestampQuery.Insert(lastIndex, "Z");
                }
            }
            return timestampQuery;
        }

        
        /// <summary>
        /// Hold reference to the storage account
        /// </summary>
        private readonly CloudStorageAccount _account;

        /// <summary>
        /// Hold the table client
        /// </summary>
        private readonly CloudTableClient _tableClient;

        private const string PartitionKeyStr = "PartitionKey";
        private const string TimestampKeyStr = "Timestamp";
        private const string DatetimeStr = "datetime";
    }
}
