# This repository contains content for the MLADS Spring 2017 (June 8-9, 2017) tutorial "Operationalization using Microsoft R Server on single node machines and Spark clusters".

## Tutorial Prerequisites
* Please bring a wireless enabled laptop.
* Make sure your machine has an ssh client with port-forwarding capability. On Mac or Linux, simply run the ssh command in a terminal window.
On Windows, download [plink.exe](https://the.earth.li/~sgtatham/putty/latest/x86/plink.exe)
from http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html.

## Connecting to the Data Science Virtual Machine (with Spark 2.0.2) on Microsoft Azure
We will provide Azure Data Science Virtual Machines (running Spark 2.0.2) for attendees to use during the tutorial. You will use your laptop to connect to your allocated virtual machine.

* Command line to connect with ssh (Linux, Mac) - replace XXX with the DNS address of your Data Science Virtual Machine [e.g. strataABC.westus.cloudapp.azure.com]
```bash
ssh -L localhost:8787:localhost:8787 -L localhost:8088:localhost:8088 remoteuser@XXX
```
* Command line to connect with plink.exe (Windows) - run the following commands in a Windows command prompt window - replace XXX with the DNS address of your Data Science Virtual Machine
```bash
cd directory-containing-plink.exe
.\plink.exe -L localhost:8787:localhost:8787 -L localhost:8088:localhost:8088 remoteuser@XXX
```
* After connecting via the above command lines, open [http://localhost:8787/](http://localhost:8787/) in your web browser to connect to RStudio Server on your Data Science Virtual Machine<br>


<hr>


## Suggested Reading prior to tutorial date

### Microsoft R Server: <br>
Microsoft R Server [general information](https://msdn.microsoft.com/en-us/microsoft-r/rserver). <br>
Microsoft R Servers are installed on both Azure Linux DSVMs and HDInsight clusters (see below), and will be used to run R code in the tutorial.

### R-Server Operationalization service: <br>
Microsoft R Server operationalization service [general information](https://msdn.microsoft.com/en-us/microsoft-r/operationalize/about).<br>
Microsoft R Server [configuration for operationalization](https://msdn.microsoft.com/en-us/microsoft-r/operationalize/configuration-initial).

<br>
<hr>

## Datasets used in this tutorial


<br>
<hr>

## Platforms & services for hands-on exercises or demos
### Azure Linux DSVM (Data Science Virtual Machine)
Information on Linux DSVM: https://azuremarketplace.microsoft.com/en-us/marketplace/apps/microsoft-ads.linux-data-science-vm<br>
The Linux DSVM has Spark (2.0.2) installed, as well as Yarn for job management, as well as HDFS. So, you can use the DSVM to run regular R code as well as code that run on Spark (e.g. using SparkR package). You will use DSVM as a single node Spark machine for hands-on exercises. We will provision these machines and assign them to you at the beginning of the tutorial.<br>

### Azure HDInsight Spark clusters
Information about HDInsight Spark clusters: https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-apache-spark-overview<br>

