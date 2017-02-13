# This folder contains pySpark notebooks for published walk-throughs
<br>

## Description:  ##

For conceptual documentation and walkthroughs, see the following topics: 

>**Overview:** <br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview)

>**Exploration, and modeling**: <br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-data-exploration-modeling](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-data-exploration-modeling)<br><br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-advanced-data-exploration-modeling](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-advanced-data-exploration-modeling)

>**Model operationalization and consumption for scoring:** <br>
[https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-model-consumption](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-model-consumption)

<br>
> These documents provide walkthroughs with code that runs on Spark 1.6. However, we have now released notebooks for both Spark 1.6 and Spark 2.0 that can be run on the Jupyter notebook servers of Azure Spark HDInsight clusters. Links to these notebooks are provided below.

------------------------------------------------------------------------------------------------------------
## Spark 1.6 NBs (to be run in the pyspark kernel of Jupyter Notebook server): ##

NOTE: These notebooks have been tested on Spark 1.6.4 HDInsight clusters.

> **[pySpark-machine-learning-data-science-spark-data-exploration-modeling.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/pySpark-machine-learning-data-science-spark-data-exploration-modeling.ipynb)**

Provides information on how to perform data exploration, modeling, and scoring with several different algorithms
<br>


> **[pySpark-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/pySpark-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb)**

Includes topics in notebook #1, and model development using hyperparameter tuning and cross-validation
<br>

> **[pySpark-machine-learning-data-science-spark-model-consumption.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/pySpark-machine-learning-data-science-spark-model-consumption.ipynb)**

Shows how to operationalize a saved model using Python on HDInsight clusters
<br>

<br>
<br>

-------------------------------------------------------------------------------------------------------------
## Spark 2.0 NBs (to be run in the pySpark3 kernel of Jupyter notebook server): ##

NOTES: 


1. These notebooks have been tested on Spark 2.0.2 HDInsight clusters
2. In addition to the NYC Taxi trip and fare dataset which we used for the Spark 1.6 notebooks, we have used the Airline On-time departure dataset (below) for Spark 2.0. This dataset shows: (i) how to integrate weather features into the model, and (ii) how to deal with a large number of categorical features in modeling (e.g. the distinct number of airports).

<BR>
> **[Spark2.0-pySpark3-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark2.0-pySpark3-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb)**

This file provides information on how to perform data exploration, modeling, and scoring in Spark 2.0 clusters.

> **[Spark2.0-pySpark3_NYC_Taxi_Tip_Regression.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark2.0_pySpark3_NYC_Taxi_Tip_Regression.ipynb)**

This file shows how to perform data wrangling (Spark SQL and dataframe operations), exploration, modeling and scoring using the NYC Taxi trip and fare data-set described [here](https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview).

> **[Spark2.0-pySpark3_Airline_Departure_Delay_Classification.ipynb](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/Spark2.0_pySpark3_Airline_Departure_Delay_Classification.ipynb)**

This file shows how to perform data wrangling (Spark SQL and dataframe operations), exploration, modeling and scoring using the well-known Airline On-time departure dataset from 2011 and 2012. We integrated the airline dataset with the airport weather data (e.g. windspeed, temperature, altitude etc.) prior to modeling, so these weather features can be included in the model.

See the following links for information about airline on-time departure dataset and weather dataset:

- Airline on-time departure data: [http://www.transtats.bts.gov/ONTIME/](http://www.transtats.bts.gov/ONTIME/)


- Airport weather data: [https://www.ncdc.noaa.gov/](https://www.ncdc.noaa.gov/) 


<br>

> **Operationalization of a model and model consumption for scoring**

See the [Spark 1.6 document on consumption](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/pySpark/pySpark-machine-learning-data-science-spark-model-consumption.ipynb) for an example of how to operationalize a model. To use this on Spark 2.0, replace the Python code file with [this file](https://github.com/Azure/Azure-MachineLearning-DataScience/blob/master/Misc/Spark/Python/Spark2.0_ConsumeRFCV_NYCReg.py).

 
-------------------------------------------------------------------------------------------------------------
