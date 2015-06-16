using System.Collections.Generic;

namespace AzureMLClient.Contracts
{
    public class BatchRequest
    {
        public IDictionary<string, string> GlobalParameters { get; set; }

        public AzureBlobDataReference Input { get; set; }

        public AzureBlobDataReference Output { get; set; }
    }
}
