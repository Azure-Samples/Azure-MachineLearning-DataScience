This folder has content for the Strata San Jose March 2017 tutorial "Scalable Data Science with R, from Single Nodes to Spark Clusters".

## Tutorial link (Strata San Jose, March 2017)
https://conferences.oreilly.com/strata/strata-ca/public/schedule/detail/55806

## Tutorial Prerequisites
* Make sure your machine has an ssh client with port-forwarding capability. On Mac or Linux, simply run the ssh command in a terminal window.
On Windows, download [plink.exe](https://the.earth.li/~sgtatham/putty/latest/x86/plink.exe)
from http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html.

## Connecting to the Data Science Virtual Machine (with Spark 2.0.2) on Microsoft Azure
* Command line to connect with ssh (Linux, Mac) - replace XXX with the number of your cluster
```bash
ssh -L localhost:8787:localhost:8787 remoteuser@r-server.kddXXX-ssh.azurehdinsight.net
```
* Command line to connect with plink.exe (Windows) - run the following commands in a Windows command prompt window - replace XXX with the number of your cluster
```bash
cd directory-containing-plink.exe
.\plink.exe -L localhost:8787:localhost:8787 remoteuser@r-server.kddXXX-ssh.azurehdinsight.net
```
* After connecting via the above command lines, open [http://localhost:8787/](http://localhost:8787/) in your web browser to connect to RStudio Server on the edge node of your cluster

## Suggested Reading and Tutorial Scripts [Links are to earlier versions, will be updated in March 2017]
* for _Exploration and visualization using SparkSQL and R_
 * [Sample script](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/KDDCup2016/Code/SparkSQL/SparkSQL.R)
* for _End to end scalable data analysis in R: Data exploration, visualization, modeling and deployment using distributed R functions and Hadoop/Spark_
 * [SparkR, ScaleR, and AzureML scripts for Airline Delay dataset](https://github.com/Azure/Azure-MachineLearning-DataScience/tree/master/Misc/KDDCup2016/Code/MRS)
 * [SparkR and sparklyr scripts for NYC Taxi dataset](https://github.com/Azure/Azure-MachineLearning-DataScience/tree/master/Misc/KDDCup2016/Code/SparkR)

* for _Distributed model training and parameter optimization: Learning Curves on Big Data_
 * http://blog.revolutionanalytics.com/2015/09/why-big-data-learning-curves.html
 * http://blog.revolutionanalytics.com/2016/03/learning-from-learning-curves.html
 * [Sample scripts](https://github.com/Azure/Azure-MachineLearning-DataScience/tree/master/Misc/KDDCup2016/Code/learning_curves)

* for _Parallel models: training many parallel models for hierarchical time series optimization_
 * [Sample script](https://github.com/Azure/Azure-MachineLearning-DataScience/tree/master/Misc/KDDCup2016/Code/UseCaseHTS)

## Video Record of an earlier version of this tutorial (presented at the KDD conference in August 2016)
http://videolectures.net/kdd2016_tutorial_scalable_r_on_spark/?q=Spark
