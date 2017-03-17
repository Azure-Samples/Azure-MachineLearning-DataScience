# pySpark Jupyter notebooks for data science on HDInsight Spark 1.6 and Spark 2.0 clusters
<br>

## Description:
The Spark 1.6 and Spark 2.0 folders in this directory contain pySpark notebooks that show how to use HDInsight Spark to complete common data science tasks on these respective cluster versions of Spark.

For documentation that walks you through these tasks, see the following topics: 


>**Overview:** <br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview)

>**Exploration, and modeling**: <br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-data-exploration-modeling](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-data-exploration-modeling)<br><br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-advanced-data-exploration-modeling](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-advanced-data-exploration-modeling)

>**Model operationalization and consumption for scoring:** <br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-model-consumption](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-model-consumption)

<br>
> The descriptions above are for code that runs on Spark 1.6. However, we now have notebooks for Spark 2.0 as well that can be run on the Jupyter notebook servers of Azure Spark HDInsight clusters. Links to these two sets of notebooks are provided below.
> 
<br>

------------------------------------------------------------------------------------------------------------
## Spark 1.6 Notebooks (to be run in the pyspark kernel of Jupyter notebook server): ##

NOTE: Tested on Spark 1.6.4 HDInsight clusters.

### Wrangling, exploration and modeling

> **[pySpark-machine-learning-data-science-spark-data-exploration-modeling.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark1.6/pySpark-machine-learning-data-science-spark-data-exploration-modeling.ipynb)**

Provides information on how to perform data exploration, modeling, and scoring with several different algorithms.
<br>


> **[pySpark-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/Spark1.6/pySpark/pySpark-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb)**

Adds model development using hyperparameter tuning and cross-validation to the topics covered in the first notebook
<br>

### Operationalization of a model and model consumption for scoring

> **[pySpark-machine-learning-data-science-spark-model-consumption.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark1.6/pySpark-machine-learning-data-science-spark-model-consumption.ipynb)**

Shows how to operationalize a saved model using python on HDInsight clusters.

<br>

--------------------------------------------------------------------------------------------------------------------
## Spark 2.0 Notebooks (to be run in the pySpark3 kernel of Jupyter notebook server):

<br>
NOTES: 

1. Currently tested on Spark 2.0.2 HDInsight clusters
2. In addition to the NYC Taxi trip and fare dataset which we used for the Spark 1.6 notebooks, for Spark 2.0 we've used the Airline On-time departure dataset (below). This dataset shows: (i) how to integrate weather features in the model, and (ii) how to deal with large number of categorical features in modeling (e.g. the distinct number of airports).
3. We provide a python file on how to consume ML models trained in Spark 2.0.2.
<br>
<br>

### Wrangling, exploration and modeling

> **[Spark2.0-pySpark3_NYC_Taxi_Tip_Regression.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark2.0/Spark2.0_pySpark3_NYC_Taxi_Tip_Regression.ipynb)**

This file shows how to perform data wrangling (Spark SQL and dataframe operations), exploration, modeling and scoring using the NYC Taxi trip and fare data-set (see above links).

> **[Spark2.0-pySpark3_Airline_Departure_Delay_Classification.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark2.0/Spark2.0_pySpark3_Airline_Departure_Delay_Classification.ipynb)**

This file shows how to perform data wrangling (Spark SQL and dataframe operations), exploration, modeling and scoring using the well-known Airline On-time departure dataset from 2011 and 2012. We integrated the airline dataset with the airport weather data (e.g. windspeed, temperature, altitude etc.) prior to modeling, so these weather features can be included in the model.

See the following links for information about airline on-time departure dataset and weather dataset:

- Airline on-time departure data: [http://www.transtats.bts.gov/ONTIME/](http://www.transtats.bts.gov/ONTIME/)


- Airport weather data: [https://www.ncdc.noaa.gov/](https://www.ncdc.noaa.gov/) 
<br>
<br>

> **[Spark2.0-pySpark3-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark2.0/Spark2.0-pySpark3-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb)**

The Spark 2.0 notebooks on the NYC taxi and airline flight delay data-sets can take 10 minutes or more to run (depending on the size of your HDI cluster). We have created this notebook which shows many aspects of the data exploration, visualization and ML model training in a notebook that takes less time to run with a down-sampled NYC data set, where the taxi and fare files have been pre-joined. This notebook takes a much shorter time to finish (typically 2-3 minutes), and may be a good starting point for quickly exploring the code we have provided for Spark 2.0.


### Operationalization of a model and model consumption for scoring

Please see [the description above for Spark 1.6](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark1.6/pySpark-machine-learning-data-science-spark-model-consumption.ipynb).
<br> 
The Python code file provided in the notebook for Spark 1.6 needs to be replaced with [this file](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/Python/Spark2.0_ConsumeRFCV_NYCReg.py), to use it with Spark 2.0.
<br>

 
--------------------------------------------------------------------------------------------------------------------