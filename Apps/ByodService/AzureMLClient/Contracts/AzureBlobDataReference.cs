namespace AzureMLClient.Contracts
{
    public class AzureBlobDataReference
    {
        public string ConnectionString { get; set; }

        public string RelativeLocation { get; set; }

        public string BaseLocation { get; set; }

        public string SasBlobToken { get; set; }
    }
}
