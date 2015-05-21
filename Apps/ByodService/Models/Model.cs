using System;
using System.ComponentModel.DataAnnotations;

namespace MarketBasket.Web.Models
{

    public class Model
    {
        public Model()
        {
            MaxItemsSetSize = 3;
            MinumumOccurrences = 6;
        }

        [Key]
        public string Name { get; set; }
        public int MinumumOccurrences { get; set; }
        public int MaxItemsSetSize { get; set; }
        public string Status { get; set; }
        public bool HasData { get; set; }
        public bool NeedsTraining { get; set; }
        public bool ReadyForScoring { get; set; }
        public bool IsTraining { get; set; }
        public DateTimeOffset? DataUploadTime { get; set; }
        public DateTimeOffset? TrainingStartTime { get; set; }
        public DateTimeOffset? TrainingEndTime { get; set; }
    }


}