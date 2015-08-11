using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using SignalR.Hubs;
using System.Net.Http;
using System.Net;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;

namespace SignalRChat.Hubs
{
    public class Chat : Hub
    {
        public async Task SendMessage(string name, string message)
        {
            Clients.PublishMessage(name, message);
        }
    }
}