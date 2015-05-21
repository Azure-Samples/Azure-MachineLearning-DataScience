using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AzureMLClient.Contracts
{
    public class BatchStatus
    {
        public BatchScoreStatusCode StatusCode { get; set; }

        /// <summary>
        /// Blob locations for the potential multiple batch execution outputs. 
        /// </summary>
        public IDictionary<string, AzureBlobDataReference> Results { get; set; }

        /// <summary>
        /// Error message when it fails
        /// </summary>
        public string Details { get; set; }
    }
}
