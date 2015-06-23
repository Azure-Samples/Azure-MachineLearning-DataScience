using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MarketBasket.Core
{
    public class ModelData : TableEntity
    {
        public string Status { get; set; }
        public string ExperimentId { get; set; }
        public string DataSourceId { get; set; }
        public string WebServiceGroupId { get; set; }
        public string ScoringUrl { get; set; }
        public string ScoringAccessKey { get; set; }
        public string DataFileBlobName { get; set; }
        public int SupportThreshhold { get; set; }
        public int MaxItemSetSize { get; set; }
        public bool TrainingInvalidated { get; set; }
        public bool IsTraining { get; set; }
        public DateTimeOffset? DataUploadTime { get; set; }
        public DateTimeOffset? TrainingStartTime { get; set; }
        public DateTimeOffset? TrainingEndTime { get; set; }

    }
}
