# This folder has content for the Strata San Jose March 2017 tutorial "Scalable Data Science with R, from Single Nodes to Spark Clusters".

## Tutorial link (Strata San Jose, March 2017)
https://conferences.oreilly.com/strata/strata-ca/public/schedule/detail/55806

## Tutorial Prerequisites
* Please bring a wireless enabled laptop.
* Make sure your machine has an ssh client with port-forwarding capability. On Mac or Linux, simply run the ssh command in a terminal window.
On Windows, download [plink.exe](https://the.earth.li/~sgtatham/putty/latest/x86/plink.exe)
from http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html.

## Connecting to the Data Science Virtual Machine (with Spark 2.0.2) on Microsoft Azure
* Command line to connect with ssh (Linux, Mac) - replace IPaddress IP of your DSVM
```bash
ssh -L localhost:8787:localhost:8787 remoteuser@IPaddress
```
* Command line to connect with plink.exe (Windows) - run the following commands in a Windows command prompt window - replace XXX with the number of your cluster
```bash
cd directory-containing-plink.exe
.\plink.exe -L localhost:8787:localhost:8787 remoteuser@IPaddress
```
* After connecting via the above command lines, open [http://localhost:8787/](http://localhost:8787/) in your web browser to connect to RStudio Server on the edge node of your cluster

## Connecting to R server operationalization service on your DSVM
* Command line to connect with ssh (Linux, Mac) - replace IPaddress IP of your DSVM
```bash
.\plink.exe -L localhost:12800:localhost:12800 remoteuser@IPaddress
```
<hr>

## Suggested Reading and Tutorial Scripts [Links are to earlier versions, will be updated in March 2017]

* SparkR (Spark 2.0.2): https://spark.apache.org/docs/2.0.2/api/R/index.html

* sparklyR: http://spark.rstudio.com/

* R-Server Operationalization service: https://msdn.microsoft.com/en-us/microsoft-r/operationalize/configuration-initial
<hr>
## Video Record of an earlier version of this tutorial (presented at the KDD conference in August 2016)
http://videolectures.net/kdd2016_tutorial_scalable_r_on_spark/?q=Spark
