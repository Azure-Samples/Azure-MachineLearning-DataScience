# Intelligent Mall Kiosk Demo
![Screenshot][1]
[1]: ./screenshot.jpg

### Requirements
1. Install Visual Studio 2013.
2. Make sure there is a webcam installed on your system, and that the microphone of the webcam works. We recommend using a high quality webcam like this one: [LifeCam Studio](http://www.microsoft.com/hardware/en-us/p/lifecam-studio).
3. Ensure that you have set the default sound capture device in windows.  You may have to disable other microphones to get ti to use the one you want.

### Setting up
1. Edit the app.config file and enter the API key for the [Face](http://gallery.azureml.net/MachineLearningAPI/b0b2598aa46c4f44a08af8891e415cc7), [Speech](http://gallery.azureml.net/MachineLearningAPI/89d229231a72471ebf7280fb5bd3e18c), and [Text-Analytics](http://gallery.azureml.net/MachineLearningAPI/6948e0a54fe44e6fb70cbcc143b31298) API.  You will need to sign up using the links in the file.

### Using the application
The application is easy to use (Remember it will not work unless you have set the right API keys, see previous step).
First of all you should see a live video stream of your webcam. If you do not see that, verify that your webcam is working.

There are only two operations you can perform:

The blue button will take a screenshot of the people in front of the webcam, call the Face APIs to analyse age and gender, display that information on the top right of the screen – and then recommend a website that that individual/set of individuals are likely to be interested in.

The red button will start audio capturing, and will provide textual feedback (Using the Speech API) on the speech being captured so far on the top right of the screen. If you don’t see anything happening, make sure your microphone/webcam microphone is working.

Once you are done speaking, click the "stop recording button", we will call the Text Analytics API to get sentiment analysis of what the customer has said (using the output of the Speech API).


### Customizing your Demo
You can modify the URLs that show up based on age/gender by tweaking the app.config file as well.
In the config file you can also change what recommendation shows based on the speech recorded. When you press the red button, we will use the Speech APIs to convert Speech to Text. 
If the text contains either of the keywords below, the URL right under the keyword will appear as a recommendation.

### Recognizing specific people
You could tweak the code to recognize specific people, but it will require you to change a few things in the code (you are now in the Advanced scenarios). You will need to to train the model ahead of time.
Take a look at the code at the TrainFaceDetector method in MainWindow.xaml.cs. 
If you want to customize the visualization on the screen based on the person recognized (i.e. for instance displaying a specific age/gender for that person), take a look at the FaceMarker constructor on FaceMarker.xaml.cs.
