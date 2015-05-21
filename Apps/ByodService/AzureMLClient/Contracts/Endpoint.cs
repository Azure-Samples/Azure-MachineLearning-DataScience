using System;

namespace AzureMLClient.Contracts
{
    public class Endpoint
    {
        public string Name { get; set; }

        public string Description { get; set; }

        public DateTime CreationTime { get; set; }

        public string WorkspaceId { get; set; }

        public string WebServiceId { get; set; }

        public string HelpLocation { get; set; }

        public string PrimaryKey { get; set; }

        public string SecondaryKey { get; set; }

        public string ApiLocation { get; set; }

        public string ExperimentLocation { get; set; }

        public EndpointResource[] Resources { get; set; }

        public DateTime? Version { get; set; }

        public int MaxConcurrentCalls { get; set; }

        public DiagnosticsTraceLevel DiagnosticsTraceLevel { get; set; }

        public ThrottleLevel ThrottleLevel { get; set; }
    }

    public class EndpointCreate
    {
        public string Description { get; set; }

        public int MaxConcurrentCalls { get; set; }

        public ThrottleLevel ThrottleLevel { get; set; }
    }
}
