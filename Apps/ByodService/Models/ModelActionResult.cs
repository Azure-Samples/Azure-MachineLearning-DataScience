using System;

namespace MarketBasket.Web.Models
{

    public class ModelActionResult
    {
        public bool Success { get; set; }

        public string Message { get; set; }

        public DateTimeOffset MessageTime { get { return DateTimeOffset.Now; } set { } }
    }


}