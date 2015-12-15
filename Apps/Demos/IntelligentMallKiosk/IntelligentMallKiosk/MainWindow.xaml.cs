using System;
using System.Collections.Generic;
using System.Configuration;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Reflection;
using System.Printing;
using MS.Internal.ReachFramework;

using System.IO;
using System.Threading;
using Microsoft.ProjectOxford.Face.Contract;
using MicrosoftProjectOxford;



namespace MLMarketplaceDemo
{
    public enum RecordingState
    {
        Stopped,
        Monitoring,
        Recording,
        RequestedStop
    }

    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        RecordingState recordingState = RecordingState.Monitoring;
        String WavFileUriPath;
        List<Brush> brushList;
        MicrophoneRecognitionClient m_micClient;
        string fullText;
        System.Windows.Forms.WebBrowser browser1;


        Configuration configManager;
        KeyValueConfigurationCollection confCollection;
        int pingPong = 0;


        public MainWindow()
        {
            configManager = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
            confCollection = configManager.AppSettings.Settings;

            // find a place to copy audio file.
            WavFileUriPath = System.IO.Path.Combine(Directory.GetCurrentDirectory(), "audio1.wav"); ;

            InitializeComponent();
            ButtonState = "Record";
            brushList = new List<Brush>();
            brushList.Add(Brushes.Crimson);
            brushList.Add(Brushes.ForestGreen);
            brushList.Add(Brushes.Navy);
            brushList.Add(Brushes.Goldenrod);
            brushList.Add(Brushes.Olive);
            brushList.Add(Brushes.OrangeRed);
            brushList.Add(Brushes.Indigo);

            //browser1.Scr
            browser1 = (System.Windows.Forms.WebBrowser)winformhost1.Child;
        }

        String ExtractParagraphFromJSON(string jsonResponse)
        {
            dynamic foo = Newtonsoft.Json.Linq.JObject.Parse(jsonResponse);
            String result = foo.header.name;

            return result;
        }

        private void btnAnalyze_Click(object sender, RoutedEventArgs e)
        {
            DisplayAnalysis();
        }

        private void DisplayAnalysis()
        {
            AnalyzeText(this.fullText);
        }

        private bool ignoreNextString = false;
        private void AnalyzeText(string textBody)
        {
            if (String.IsNullOrEmpty(textBody))
            {
                textBody = userInput.Text;
                ignoreNextString = true;
            }

            if (String.IsNullOrEmpty(textBody))
            {
                this.Dispatcher.Invoke((Action)(() =>
                {
                    userInput.Text = "Can't hear you. Please speak louder!";

                }));

                return;
            }

            if (pingPong > 0)
            {
                textBody += " " + partialString;
            }

            this.Dispatcher.Invoke((Action)(() =>
            {
                BrushConverter bc = new BrushConverter();
                userInput.Text = "";
            }));


            var result = TextAnalyzer.AnalyzeText(textBody);

            List<string> keyPhrases = new List<string>();
            foreach (string phrase in result.KeyPhrases)
            {
                keyPhrases.Add(phrase);
            }

            this.Dispatcher.Invoke((Action)(() =>
            {
                mySentiment.Sentiment = result.Score;
                userInput.Text = textBody;

                smileGrid.Visibility = System.Windows.Visibility.Hidden;
                resultGrid.Visibility = System.Windows.Visibility.Visible;


                if (true)
                {
                    if (textBody.ToLower().Contains(confCollection["SpeechKeyword1"].Value))
                    {
                        browser1.Navigate(
                            confCollection["SpeechKeyword1Url"].Value);
                    }
                    else if (textBody.ToLower().Contains(confCollection["SpeechKeyword2"].Value))
                    {
                        browser1.Navigate(
                            confCollection["SpeechKeyword2Url"].Value);
                    }
                }

            }));
        }

        private Brush RedColorBrush = new SolidColorBrush(Colors.Crimson);
        private Brush GreenColorBrush = new SolidColorBrush(Colors.Green);
        private Brush YelloColorBrush = new SolidColorBrush(Colors.Gold);

        private Brush GetScoreColor(double score)
        {
            if (score < 0.3)
            {
                return RedColorBrush;
            }
            else
            {
                if (score > 0.6)
                {
                    return GreenColorBrush;
                }
            }

            return YelloColorBrush;
        }

        private string buttonState;
        private String ButtonState
        {
            get
            {
                return buttonState;
            }
            set
            {
                buttonState = value;
            }
        }


        bool recording = false;


        public Face[] RecognizedFaces = null;

        /// <summary>
        /// Analyze the image and show a recommended URL given age/gender.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private async void btnAnalyzeImage(object sender, RoutedEventArgs e)
        {
            StatusText.Text = "Analyzing...";

            RecognizedFaces = await ProcessImage();
            userInput.Text = "";


            string url = "";

            if (RecognizedFaces == null)
            {
                StatusText.Text = "Null returned";
                return;
            }


            if (RecognizedFaces.Length == 1)
            {
                // A single person.

                Face singleFace = RecognizedFaces[0];

                NamedFace namedFace = singleFace as NamedFace;
                if (namedFace.Name == "Scott")
                {
                    url = "http://www.sephora.com/polo-red-P380994";
                }
                else if (namedFace.Name == "Kevin")
                {
                    url = @"http://www.mcdonalds.com/us/en/food.html";
                }
                else if (String.Compare(singleFace.Attributes.Gender, "male", true) == 0)
                {
                    // male single person
                    if (singleFace.Attributes.Age < 12)
                    {
                        // a single child?
                        url = confCollection["MaleYoungerThan12"].Value;
                    }
                    else if (singleFace.Attributes.Age < 18)
                    {
                        url = confCollection["MaleYoungerThan18"].Value;
                    }
                    else if (singleFace.Attributes.Age < 25)
                    {
                        url = confCollection["MaleYoungerThan25"].Value;
                    }
                    else if (singleFace.Attributes.Age < 32)
                    {
                        url = confCollection["MaleYoungerThan32"].Value;
                    }
                    else if (singleFace.Attributes.Age < 40)
                    {
                        url = confCollection["MaleYoungerThan40"].Value;
                    }
                    else if (singleFace.Attributes.Age < 50)
                    {
                        url = confCollection["MaleYoungerThan50"].Value;
                    }
                    else if (singleFace.Attributes.Age < 55)
                    {
                        url = confCollection["MaleYoungerThan55"].Value;
                    }
                    else if (singleFace.Attributes.Age < 60)
                    {
                        url = confCollection["MaleYoungerThan60"].Value;
                    }
                    else
                    {
                        url = confCollection["MaleOlder"].Value;
                    }
                }
                else
                {
                    // female single person
                    if (singleFace.Attributes.Age < 12)
                    {
                        url = confCollection["FemaleYoungerThan12"].Value;
                    }
                    else if (singleFace.Attributes.Age < 18)
                    {
                        url = confCollection["FemaleYoungerThan18"].Value;
                    }
                    else if (singleFace.Attributes.Age < 25)
                    {
                        url = confCollection["FemaleYoungerThan25"].Value;
                    }
                    else if (singleFace.Attributes.Age < 32)
                    {
                        // female single person
                        url = confCollection["FemaleYoungerThan32"].Value;
                    }
                    else if (singleFace.Attributes.Age < 40)
                    {
                        url = confCollection["FemaleYoungerThan40"].Value;
                    }
                    else if (singleFace.Attributes.Age < 50)
                    {
                        url = confCollection["FemaleYoungerThan50"].Value;
                    }
                    else if (singleFace.Attributes.Age < 60)
                    {
                        url = confCollection["FemaleYoungerThan60"].Value;
                    }
                    else
                    {
                        url = confCollection["FemaleOlder"].Value;
                    }
                }
            }

            if (RecognizedFaces.Length >= 2)
            {

                bool isChildPresent = false;
                foreach (Face face in RecognizedFaces)
                {
                    if (face.Attributes.Age <= 12)
                    {
                        isChildPresent = true;
                    }
                }

                if (isChildPresent)
                {
                    // There is a family here.
                    url = confCollection["MorethanOnePersonAndChild"].Value;
                }
                else
                {
                    // at least two adult friends.
                    url = confCollection["TwoOrMoreAdults"].Value;
                }
            }

            browser1.Navigate(url);
            StatusText.Text = "Done";
        }


        /// <summary>
        /// Analyze speech input
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnAnalyzeSpeech_Click(object sender, RoutedEventArgs e)
        {
            ignoreNextString = false;
            AudioControlsGrid.Visibility = Visibility.Visible;

            if (ButtonState == "Record")
            {
                this.fullText = null;
                recording = true;
                BrushConverter bc = new BrushConverter();
                mySentiment.Sentiment = 0.5;
                userInput.Text = "";

                recordGrid.Visibility = System.Windows.Visibility.Hidden;
                recordingdGrid.Visibility = System.Windows.Visibility.Visible;

                recordingState = RecordingState.Recording;

                string speechAPIKey = confCollection["SpeechRecognitionAPIKey"].Value;

                MicrophoneRecognitionClient intentMicClient =
                                SpeechRecognitionServiceFactory.CreateMicrophoneClient(SpeechRecognitionMode.LongDictation,
                                                                                       "en-us",
                                                                                       speechAPIKey);

                m_micClient = intentMicClient;

                // Event handlers for speech recognition results
                m_micClient.OnResponseReceived += this.OnResponseReceivedHandler;
                m_micClient.OnPartialResponseReceived += this.OnPartialResponseReceivedHandler;
                //m_micClient.OnConversationError += OnConversationErrorHandler;

                // First send of audio data to service
                m_micClient.StartMicAndRecognition();

                ButtonState = "Finish";
            }
            // Finish the recording
            else if (ButtonState == "Finish")
            {
                Thread.Sleep(1000);
                recording = false;
                m_micClient.EndMicAndRecognition();
                recordGrid.Visibility = System.Windows.Visibility.Visible;
                recordingdGrid.Visibility = System.Windows.Visibility.Hidden;

                ButtonState = "Record";

                DisplayAnalysis();

                // Stop recording.
                Stop();
            }
        }


        public void HideScriptErrors(WebBrowser wb, bool Hide)
        {
            FieldInfo fiComWebBrowser = typeof(WebBrowser).GetField("_axIWebBrowser2", BindingFlags.Instance | BindingFlags.NonPublic);
            if (fiComWebBrowser == null)
                return;

            object objComWebBrowser = fiComWebBrowser.GetValue(wb);

            if (objComWebBrowser == null)
                return;

            objComWebBrowser.GetType().InvokeMember("Silent", BindingFlags.SetProperty, null, objComWebBrowser, new object[] { Hide });

        }


        void OnResponseReceivedHandler(object sender, SpeechResponseEventArgs e)
        {
            if (ignoreNextString)
            {
                return;
            }

            if (recording)
            {
                for (int i = 0; i < e.PhraseResponse.Results.Length; i++)
                {
                    this.Dispatcher.Invoke((Action)(() =>
                    {
                        this.fullText += e.PhraseResponse.Results[i].DisplayText + " ";
                        userInput.Text = fullText;
                       /* userInput.Text = e.PhraseResponse.Results[i].DisplayText;
                        this.fullText += " " + userInput.Text;*/
                        pingPong = 0;
                    }));
                }
            }
        }

        private String partialString;
        /// <summary>
        ///     Called when a partial response is received.
        /// </summary>
        void OnPartialResponseReceivedHandler(object sender, PartialSpeechResponseEventArgs e)
        {
            if (recording)
            {
                pingPong++;
                this.Dispatcher.Invoke((Action)(() =>
                {
                    partialString = e.PartialResult;
                    userInput.Text = this.fullText + partialString;
                    /*partialString = e.PartialResult;
                    userInput.Text = this.fullText + e.PartialResult;
                     */
                }));
            }
        }


        /// <summary>
        /// Train the model to detect particular faces.
        /// </summary>
        private async void TrainFaceDetector(object sender, RoutedEventArgs e)
        {
            StatusText.Text = "Training...";
            ImageAnalyzer analyzer = new ImageAnalyzer();
            await analyzer.TrainFaceDetector();
        }

        private async Task<Face[]> ProcessImage()
        {
            CameraVideoDeviceControl.TakeSnapshotCallback();
            Face[] faces = await imageProcessor();
            return faces;
        }


        private async Task<Face[]> imageProcessor()
        {
            string imageFileUriPath = System.IO.Path.Combine(Directory.GetCurrentDirectory(), Guid.NewGuid().ToString() + ".jpg");
            FileStream fileStream = TakeSnapshotUsingTemporaryFile(imageFileUriPath);

            Face[] faces;

            try
            {
                ImageAnalyzer analyzer = new ImageAnalyzer();
                faces = await analyzer.AnalyzeImageUsingHelper(fileStream);
            }
            catch (Exception e)
            {
                Ids.Children.Clear();
                return null;
            }

            double videoWidth = CameraVideoDeviceControl.ActualWidth * WebcamDevice.thisDpiWidthFactor;
            double videoHeight = CameraVideoDeviceControl.ActualHeight * WebcamDevice.thisDpiHeightFactor;

            double imageWidth = OutputImage.ActualWidth;
            double imageHeight = OutputImage.ActualHeight;

            double widthRatio = videoWidth / imageWidth;
            double heightRatio = videoHeight / imageHeight;

            this.Dispatcher.Invoke((Action)(() =>
            {
                UpdateUIWithFaces(faces, widthRatio, heightRatio);
            }));

            fileStream.Close();

            File.Delete(imageFileUriPath);

            return faces;

        }

        private FileStream TakeSnapshotUsingTemporaryFile(string imageFileUriPath)
        {
            try
            {
                this.Dispatcher.Invoke((Action)(() =>
                {
                    OutputImage.Source = ConvertToImageSource(CameraVideoDeviceControl.SnapshotBitmap);
                    CameraVideoDeviceControl.SnapshotBitmap.Save(imageFileUriPath, System.Drawing.Imaging.ImageFormat.Jpeg);
                }));

            }
            catch (Exception)
            {
                // every once in a while we get a GDI error... not sure what to do here...
            }

            var fileStream = File.OpenRead(imageFileUriPath);
            return fileStream;
        }

        private void UpdateUIWithFaces(Face[] faces, double widthRatio, double heightRatio)
        {
            StringBuilder usersAgeBuilder = new StringBuilder();

            // Cleaning children from stack pannels
            for (int i = canvas.Children.Count - 1; i >= 0; i--)
            {
                UIElement child = canvas.Children[i];
                if (child.GetType() == typeof(MLMarketplaceDemo.FaceMarker))
                {
                    canvas.Children.Remove(child);
                }
            }

            //userInputPannel.Children.Clear();
            Ids.Children.Clear();

            if (faces != null)
            {
                int index = 0;
                foreach (var face in faces)
                {

                    //string age = face.Attributes.Age.ToString();
                    //FaceMarker  fm = new FaceMarker(age, face.Attributes.Gender);

                    FaceMarker fm = new FaceMarker(face as NamedFace);
                    
                    fm.Height = Math.Round(face.FaceRectangle.Height / heightRatio);
                    fm.Width = Math.Round(face.FaceRectangle.Width / widthRatio);
                    canvas.Children.Add(fm);
                    fm.HairlineColor = brushList[index];
                    Canvas.SetZIndex(fm, 1);
                    Canvas.SetTop(fm, Math.Round(face.FaceRectangle.Top / heightRatio));
                    Canvas.SetLeft(fm, Math.Round(face.FaceRectangle.Left / widthRatio));

                  /*  HumanIdentification identification = new HumanIdentification();
                    identification.Age = face.Attributes.Age.ToString() + " years old";
                    identification.Id = face.Attributes.Gender;
                    identification.HairlineColor = brushList[index++];
                    Ids.Children.Add(identification);*/
                }
            }
        }

        private void ComboBox_Loaded(object sender, RoutedEventArgs e)
        {
            List<string> input = new List<string>();
            input.Add("Microphone");
            input.Add("Good Feedback");
            input.Add("Bad Feedback");

            var comboBox = sender as ComboBox;
            comboBox.ItemsSource = input;
            comboBox.SelectedIndex = 0;
        }

        void OnConversationErrorHandler(object sender, SpeechErrorEventArgs e)
        {
            Console.WriteLine(e.SpeechErrorCode.ToString());
            Console.WriteLine(e.SpeechErrorText);
        }


        private void PlaySound()
        {
            string wavPath = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), WavFileUriPath);
            Uri uri = new Uri(wavPath);
            System.Media.SoundPlayer player = new System.Media.SoundPlayer(WavFileUriPath);
            player.PlaySync();

            this.Dispatcher.Invoke((Action)(() =>
            {
                recordGrid.Visibility = System.Windows.Visibility.Visible;
                recordingdGrid.Visibility = System.Windows.Visibility.Hidden;

                DisplayAnalysis();
            }));
        }

        /// <summary>
        /// The convert to image source.
        /// </summary>
        /// <param name="bitmap"> The bitmap. </param>
        /// <returns> The <see cref="object"/>. </returns>
        public static ImageSource ConvertToImageSource(System.Drawing.Bitmap bitmap)
        {
            var imageSourceConverter = new ImageSourceConverter();
            using (var memoryStream = new MemoryStream())
            {
                bitmap.Save(memoryStream, System.Drawing.Imaging.ImageFormat.Png);
                var snapshotBytes = memoryStream.ToArray();
                return (ImageSource)imageSourceConverter.ConvertFrom(snapshotBytes); ;
            }
        }


        public void Stop()
        {
            if (recordingState == RecordingState.Recording)
            {
                recordingState = RecordingState.RequestedStop;
            }
        }


        #region PRINT RELATED STUFF

        /// <summary>
        /// Prints the card layout to the default printer
        /// </summary>
        private void btnPrint_Click(object sender, RoutedEventArgs e)
        {
            PrintLayout layout = new PrintLayout();

            double videoWidth = CameraVideoDeviceControl.ActualWidth * WebcamDevice.thisDpiWidthFactor;
            double videoHeight = CameraVideoDeviceControl.ActualHeight * WebcamDevice.thisDpiHeightFactor;

            double imageWidth = layout.ImageToPrint.Width;
            double imageHeight = layout.ImageToPrint.Height;

            double widthRatio = videoWidth / imageWidth;
            double heightRatio = videoHeight / imageHeight;



            PrintDialog printDialog = new PrintDialog();
            
            // Set image and adjust to new size
            layout.ImageToPrint.Source = OutputImage.Source;

            // Add face markers
            if (RecognizedFaces != null && RecognizedFaces.Length > 0)
            {
                
                int index = 0;
                foreach (var face in RecognizedFaces)
                {
                    // Draw rectangles around faces
                    FaceMarker fm = new FaceMarker(face.Attributes.Age.ToString(), face.Attributes.Gender);
                    fm.Height = Math.Round(face.FaceRectangle.Height / heightRatio);
                    fm.Width = Math.Round(face.FaceRectangle.Width / widthRatio);
                    layout.FaceCanvas.Children.Add(fm);
                    fm.HairlineColor = brushList[index];
                    Canvas.SetZIndex(fm, 1);
                    Canvas.SetTop(fm, Math.Round(face.FaceRectangle.Top / heightRatio));
                    Canvas.SetLeft(fm, Math.Round(face.FaceRectangle.Left / widthRatio));

                }
            }



            // Get printer settings and adjust to page size

            TransformGroup transGroup = new TransformGroup();
            layout.CardToPrint.LayoutTransform = transGroup;
            
            System.Printing.PrintCapabilities capabilities = printDialog.PrintQueue.GetPrintCapabilities(printDialog.PrintTicket);
            transGroup.Children.Add(new ScaleTransform(capabilities.PageImageableArea.ExtentWidth / layout.CardToPrint.Width,
                capabilities.PageImageableArea.ExtentHeight / layout.CardToPrint.Height));

            layout.CardToPrint.LayoutTransform = transGroup;

            Size sz = new Size(capabilities.PageImageableArea.ExtentWidth, capabilities.PageImageableArea.ExtentHeight);
            layout.CardToPrint.Measure(sz);
            layout.CardToPrint.Arrange(new Rect(new Point(capabilities.PageImageableArea.OriginWidth, capabilities.PageImageableArea.OriginHeight), sz));

            // Print card layout
            printDialog.PrintVisual(layout.CardToPrint, "Results");

        }


        #endregion

        // VIDEO RELATED STUFF
        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            this.MediaDeviceList = WebcamDevice.GetVideoDevices;
            // this.VideoPreviewWidth = 320;
            this.VideoPreviewHeight = 240;

            if (this.MediaDeviceList.Count > 0)
            {
                this.SelectedVideoDevice = this.MediaDeviceList[this.MediaDeviceList.Count - 1];
            }
            else
            {
                this.SelectedVideoDevice = null;
            }

            CameraVideoDeviceControl.VideoSourceId = SelectedVideoDevice.UsbId;
        }


        /// <summary>
        /// Video preview height.
        /// </summary>
        private int videoPreviewHeight;

        /// <summary>
        /// Selected video device.
        /// </summary>
        private MediaInformation selectedVideoDevice;


        /// <summary>
        /// List of media information device available.
        /// </summary>
        private IList<MediaInformation> mediaDeviceList;

        /// <summary>
        /// Gets or sets video preview height.
        /// </summary>
        public int VideoPreviewHeight
        {
            get
            {
                return this.videoPreviewHeight;
            }

            set
            {
                this.videoPreviewHeight = value;
            }
        }

        /// <summary>
        /// Gets or sets selected media video device.
        /// </summary>
        public MediaInformation SelectedVideoDevice
        {
            get
            {
                return this.selectedVideoDevice;
            }

            set
            {
                this.selectedVideoDevice = value;
            }
        }

        /// <summary>
        /// Gets or sets media device list.
        /// </summary>
        public IList<MediaInformation> MediaDeviceList
        {
            get
            {
                return this.mediaDeviceList;
            }

            set
            {
                this.mediaDeviceList = value;
            }
        }
    }
}
