using System;

namespace AzureMLClient
{
    public class Configurations
    {
        public static readonly Uri BaseUri = new Uri("https://studio.azureml.net/");

        // obtain this from url in the azure ml studio
        public const string WorkspaceId = "9dbdce0846e64a5f9c925116e0cb6388";

        // obtain this from Setting tab in ML Studio
        public const string WorkspaceAuthToken = "74ec36c8efec4178b9c868a5df8f9926";

        // any storage account you wish to use
        public const string AzureStorageConnectionString = "DefaultEndpointsProtocol=https;AccountName=micmancloudmltest2;AccountKey=hENx5QfYRh1kKUHtBPddXiagLrsKSRaB4aK4Eep0Fl3lR00utQ87VXghVBAGd/iyuDVEH8/YHUQfJ4yswg8eeA==";
        public const string AzureStorageContainerName = "bes";

        // (optional) pre-uploaded blob for retraining - for demo purpose only
        public const string AzureStoragePreUploadedBlobName = "Iris Two Class Data.arff";

        // you can find the names below in the batch help page of the published web services.
        // the retaining trained model output port name, find this in your training experiment, or your batch help page under "Sample Response Payload, if job is finished" section
        public const string TrainedModelOutputPortName = "trained model";
        // the retaining evaluation output port name, find this in your training experiment, or your batch help page under "Sample Response Payload, if job is finished" section
        // note, this is optional and you may comment this out together with the code that attempts to read this
        public const string EvaluationOutputPortName = "evaluation result";

        // the model input name (as a resource) for the scoring experiment, you can find this name in the 'update resource' help page (linked from azure portal)
        public const string ScoringResourceName = "Training experiment [trained model]";
    }
}
