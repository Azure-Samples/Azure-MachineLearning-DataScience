using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Net.Http;
using System.Web;
using Microsoft.ProjectOxford.Face;
using Microsoft.ProjectOxford.Face.Contract;
using System.Configuration;
using System.Collections.Generic;
using System.Runtime;
using System.Collections;
using System.Reflection;

namespace MLMarketplaceDemo
{
    // Just add an additional methdo to Face.
    public class NamedFace : Face
    {
        public NamedFace(Face face)
        {
            FaceId = face.FaceId;
            FaceRectangle = face.FaceRectangle;
            FacialLandmarks = face.FacialLandmarks;
            Attributes = face.Attributes;
        }

        public String Name;
    }

    public class ImageAnalyzer
    {
        private Configuration configManager;
        private KeyValueConfigurationCollection confCollection;
        private readonly IFaceServiceClient faceDetector;

        public ImageAnalyzer()
        {
            configManager = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
            confCollection = configManager.AppSettings.Settings;
            string keyId = confCollection["FaceAPIKey"].Value; 
            faceDetector = new FaceServiceClient(keyId);
        }


        public async Task<NamedFace[]> AnalyzeImageUsingHelper(Stream stream)
        {
            Face[] faces = await faceDetector.DetectAsync(stream, false, true, true, false);
            
            NamedFace[] namedFaces = new NamedFace[faces.Length];

            //Copy to named faces vector.           
            for (int i = 0; i < faces.Length; i++)
            {
                namedFaces[i] = new NamedFace(faces[i]);
            }

            

            // TODO: Is this the right place to get the images from???
            bool identifyFaces;
            bool.TryParse(ConfigurationManager.AppSettings["IdentifySpecificPeople"] ?? "false", out identifyFaces);

            if (identifyFaces && faces.Length > 0)
            {
                var faceIds = faces.Select(face => face.FaceId).ToArray();

                var results = await faceDetector.IdentityAsync("coworkers", faceIds);

                foreach (var identifyResult in results)
                {
                    Console.WriteLine("Result of face: {0}", identifyResult.FaceId);

                    if (identifyResult.Candidates.Length == 0)
                    {
                        Console.WriteLine("No one identified");
                    }
                    else
                    {
                        var candidateId = identifyResult.Candidates[0].PersonId;
                        var person = await faceDetector.GetPersonAsync("coworkers", candidateId);

                        if (identifyResult.Candidates[0].Confidence > 0.5)
                        {
                            for (int i=0; i<namedFaces.Length; i++)
                            {
                                if (namedFaces[i].FaceId == identifyResult.FaceId)
                                {
                                    // Set name.
                                    namedFaces[i].Name=person.Name;
                                }
                            }

                            Console.WriteLine("Identified as {0}", person.Name);
                        }
                    }
                }
            }

            return namedFaces;
        }


        public async Task TrainFaceDetector()
        {
            
            string personGroupId = "coworkers";
            /*try
            {
                await faceDetector.CreatePersonGroupAsync(personGroupId, "MyCoworkers");
            }
            catch (Exception e)
            {
                // if this fails, it is probably that the group was created already.
            }
            */
            // TODO: Get this directory from the config file.
            string currentDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

            DirectoryInfo dirInfo = new DirectoryInfo( currentDir + @"\train");
            
            foreach(DirectoryInfo personDir in dirInfo.EnumerateDirectories())
            {
                List<Face> friendFaces = new List<Face>();

                if (personDir.Name != "Scott") continue;

                foreach (FileInfo imageFile in personDir.GetFiles("*.*"))
                {
                    using (Stream s = File.OpenRead(imageFile.FullName))
                    {

                        await Task.Delay(3000);
                        Face[] faces;
                        faces = await faceDetector.DetectAsync(s);

                        if (faces.Length == 0)
                        {
                            // No face detected
                            Console.WriteLine("No face detected in {0}.", imageFile.FullName);
                            continue;
                        }

                        //Assume the image contains only one face
                        friendFaces.Add(faces[0]);
                    }
                }

                var friendFaceIds = friendFaces.Select(face => face.FaceId).ToArray();
                PersonCreationResponse friend = await faceDetector.CreatePersonAsync(personGroupId, friendFaceIds, personDir.Name);
            }

            await faceDetector.TrainPersonGroupAsync(personGroupId);

            TrainingStatus trainingStatus = null;
            while (true)
            {
                trainingStatus = await faceDetector.GetPersonGroupTrainingStatusAsync(personGroupId);

                if (trainingStatus.Status != "running")
                {
                    break;
                }

                await Task.Delay(1000);
            }

        }

    }
}
