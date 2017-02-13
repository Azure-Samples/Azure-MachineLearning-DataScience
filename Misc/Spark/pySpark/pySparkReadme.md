**This folder contains pySpark notebooks for published data science walk-throughs published here: https://docs.microsoft.com/en-us/azure/machine-learning/machine-learning-data-science-spark-overview

We now have notebooks in both Spark 1.6, and Spark 2.0, that can be run on the Jupyter notebook servers of Azure Spark HDInsight clusters.**

------------------------------------------------------------------------------------------------------------
**Spark 1.6 NBs (to be run in the pyspark kernel of Jupyter notebook server):**

NOTE: Tested on Spark 1.6.4 HDInsight clusters.

> **pySpark-machine-learning-data-science-spark-data-exploration-modeling.ipynb**

Provides information on how to perform data exploration, modeling, and scoring with a few different algorithms
<br>


> **pySpark-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb**

Includes topics in notebook #1, and model development using hyperparameter tuning and cross-validation
<br>

> **pySpark-machine-learning-data-science-spark-model-consumption.ipynb**

<br>
Shows how to operationalize a saved model using python on HDInsight clusters
<br>

A detailed explanation of the 1.6 NBs are available on the above link.
<br>
<br>

-------------------------------------------------------------------------------------------------------------
**Spark 2.0 NBs (to be run in the pySpark3 kernel of Jupyter notebook server):**

NOTE: Currently tested on Spark 2.0.2 HDInsight clusters.

> **pySpark3-Spark2.0-machine-learning-data-science-spark-advanced-data-exploration-modeling.ipynb**

This file provides information on how to perform data exploration, modeling, and scoring in Spark 2.0 clusters.

> Spark2.0_pySpark3_NYC_Taxi_Tip_Regression.ipynb

This file shows how to perform data wrangling (Spark SQL and dataframe operations), exploration, modeling and scoring using the NYC Taxi trip and fare data-set (see above link).

> Spark2.0_pySpark3_Airline_Departure_Delay_Classification.ipynb

This file shows how to perform data wrangling (Spark SQL and dataframe operations), exploration, modeling and scoring using the well-known Airline On-time departure dataset from 2011 and 2012. We integrated the airline dataset with the airport weather data (e.g. windspeed, temperature, altitude etc.) prior to modeling, so these weather features can be included in the model.

See the following links for information about airline on-time departure dataset and weather dataset:
<br>

 
-------------------------------------------------------------------------------------------------------------
