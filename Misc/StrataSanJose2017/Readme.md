# This repository has content for the Strata San Jose 2017 (March 14, 9AM - 12:30PM) tutorial "Scalable Data Science with R, from Single Nodes to Spark Clusters".

## Tutorial link (Strata San Jose, March 2017)
https://conferences.oreilly.com/strata/strata-ca/public/schedule/detail/55806

## Tutorial Prerequisites
* Please bring a wireless enabled laptop.
* Make sure your machine has an ssh client with port-forwarding capability. On Mac or Linux, simply run the ssh command in a terminal window.
On Windows, download [plink.exe](https://the.earth.li/~sgtatham/putty/latest/x86/plink.exe)
from http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html.

## Connecting to the Data Science Virtual Machine (with Spark 2.0.2) on Microsoft Azure
We will provide Azure Data Science Virtual Machines (running Spark 2.0.2) for attendees to use during the tutorial. You will use your laptop to connect to your allocated virtual machine.

* Command line to connect with ssh (Linux, Mac) - replace IPaddress IP of your DSVM
```bash
ssh -L localhost:8787:localhost:8787 remoteuser@IPaddress
```
* Command line to connect with plink.exe (Windows) - run the following commands in a Windows command prompt window - replace XXX with the number of your cluster
```bash
cd directory-containing-plink.exe
.\plink.exe -L localhost:8787:localhost:8787 remoteuser@IPaddress
```
* After connecting via the above command lines, open [http://localhost:8787/](http://localhost:8787/) in your web browser to connect to RStudio Server the DSVM<br>
<b>NOTE: During the tutorial, all attendees will use RStudio Server on their DSVMs.</b>

## Connecting to R server operationalization service on your DSVM
* Command line to connect with ssh (Linux, Mac) - replace IPaddress IP of your DSVM
```bash
.\plink.exe -L localhost:12800:localhost:12800 remoteuser@IPaddress
```
<hr>
## Tutorial slides (not final until 03/14/2017) 
Slide deck: <br>
https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/StrataSanJose2017/Presentations_and_Docs/Using%20R%20for%20scalable%20data%20analytics-From%20single%20machines%20to%20Hadoop%20Spark%20clusters.pptx

## Suggested Reading prior to tutorial date

### SparkR (Spark 2.0.2): <br>
SparkR general information: http://spark.apache.org/docs/latest/sparkr.html
<br>
SparkR 2.0.2 functions: https://spark.apache.org/docs/2.0.2/api/R/index.html

### sparklyr: <br>
sparklyr general information: http://spark.rstudio.com/
<br>
sparklyr MLlib functions: sparklyr MLlib functions: http://spark.rstudio.com/mllib.html

### RevoScaleR: <br>
RevoScaleR functions: https://msdn.microsoft.com/en-us/microsoft-r/scaler/scaler

### Microsoft R Server: <br>
Microsoft R Server general information: https://msdn.microsoft.com/en-us/microsoft-r/rserver

### R-Server Operationalization service: <br>
Microsoft R Server operationalization service general information: https://msdn.microsoft.com/en-us/microsoft-r/operationalize/about
<br>
Configuring operationalization: https://msdn.microsoft.com/en-us/microsoft-r/operationalize/configuration-initial

<br>
<hr>
## Datasets used in this tutorial
### The 2013 New York City Taxi and Fare dataset (used in SparkR and sparklyr samples)
The NYC Taxi Trip data is about 20 GB of compressed comma-separated values (CSV) files (~48 GB uncompressed), comprising more than 173 million individual trips and the fares paid for each trip. Each trip record includes the pick up and drop-off location and time, anonymized hack (driver's) license number and medallion (taxi’s unique id) number. The data covers all trips in the year 2013 and is provided in the following two datasets for each month: 
* The 'trip_data' CSV files contain trip details, such as number of passengers, pick up and dropoff points, trip duration, and trip length.
* The 'trip_fare' CSV files contain details of the fare paid for each trip, such as payment type, fare amount, surcharge and taxes, tips and tolls, and the total amount paid.

For hands-on exercises, attendees will use the data from 1 month of 2013, namely December (about 1/10th of the full 2013 data)

<b>The learning problem:</b> To predict the amount of tip paid for a taxi trip (target), based on features such as trip distance, fare amount, number of passengers, time of pickup etc.

Link for further details: https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview#the-nyc-2013-taxi-data
<br>
<hr>


## Video Record of an earlier version of this tutorial (presented at the KDD conference in August 2016)
http://videolectures.net/kdd2016_tutorial_scalable_r_on_spark/?q=Spark
