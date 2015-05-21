namespace AzureMLClient.Contracts
{
    public class EndpointResource
    {
        public string Name { get; set; }

        /// <summary>
        /// Type of the WebServiceResource. Is useful when returning a WebService object in RetrieveWebService handler.
        /// </summary>
        public EndpointResourceKind Kind { get; set; }

        public AzureBlobDataReference Location { get; set; }
    }
}
