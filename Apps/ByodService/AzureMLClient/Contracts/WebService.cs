using System;
using System.Collections.Generic;

namespace AzureMLClient.Contracts
{
    public class WebService
    {
        public string Id { get; set; }

        public string Name { get; set; }

        public string Description { get; set; }

        public DateTime CreationTime { get; set; }

        public string WorkspaceId { get; set; }

        public string DefaultEndpointName { get; set; }

        public IEnumerable<Endpoint> Endpoints
        {
            get { return _endpoints.Value; }
            set
            {
                _endpoints = new Lazy<IEnumerable<Endpoint>>(() => value);
            }
        }

        private Lazy<IEnumerable<Endpoint>> _endpoints;

        public WebService()
        {
            _endpoints = new Lazy<IEnumerable<Endpoint>>(() => this.GetEndpointsAsync().Result);
        }
    }
}
