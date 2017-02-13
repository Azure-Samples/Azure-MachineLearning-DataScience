###################################################################################################################
###################################################################################################################
## THIS FILE PROVIDES THE PYTHON SCRIPTS THAT CAN BE USED TO OPERATIONALIZE SCORING 
## WITH SAVED MODELS (TRAINED IN PYSPARK3) IN SPARK 2.0.2 HDINSIGHT CLUSTERS
## YOU CAN RUN THIS USING THE FOLLOWING COMMAND: 
# curl -k --user "<admin_login>:<admin_password>" -X POST --data "{\"file\": \"wasb:///example/Spark2.0_ConsumeRFCV_NYCReg.py\"}" -H "Content-Type: application/json" "https://<HDINSIGHT_clustername>.azurehdinsight.net/livy/batches"
###################################################################################################################
###################################################################################################################


###################################################################################################################
## IMPORT LIBRARIES
###################################################################################################################
## IF FOLLOWING LIBRARIES ARE NOT INSTALLED, INSTALL THEM FIRST
#sudo python -m pip install --upgrade pip
#sudo pip install --user numpy scipy matplotlib ipython jupyter pandas sympy nose
## For installing pip on python, if not installed, see: http://stackoverflow.com/questions/6587507/how-to-install-pip-with-python-3
## Python3: sudo apt-get install python3-pip, on Ubuntu
## python3 -m pip install
###################################################################################################################
import pyspark
from pyspark.sql.types import *
from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import SQLContext
from pyspark.sql.functions import UserDefinedFunction
from pyspark.ml import PipelineModel
from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml import Pipeline
from pyspark.ml.feature import OneHotEncoder, StringIndexer, VectorIndexer
import atexit

###################################################################################################################
## CREATE SPARK CONTEXT
###################################################################################################################
sc = SparkContext(appName="PythonRFNYCPred")
sqlContext = SQLContext(sc)
atexit.register(lambda: sc.stop())
sc.defaultParallelism

###################################################################################################################
## READ IN DATA TO BE SCORED INTO A DATAFRAME FROM CSV
###################################################################################################################
taxi_valid_file_loc = "wasb://mllibwalkthroughs@cdspsparksamples.blob.core.windows.net/Data/NYCTaxi/JoinedTaxiTripFare.Point1Pct.Valid.csv"
taxi_valid_df = sqlContext.read.format("com.databricks.spark.csv").option("header", "true").option("inferschema", "true").option("mode", "DROPMALFORMED").load(taxi_valid_file_loc)

## CREATE A CLEANED DATA-FRAME BY DROPPING SOME UN-NECESSARY COLUMNS & FILTERING FOR UNDESIRED VALUES OR OUTLIERS
taxi_df_valid_cleaned = taxi_valid_df.drop('medallion').drop('hack_license').drop('store_and_fwd_flag').drop('pickup_datetime')\
    .drop('dropoff_datetime').drop('pickup_longitude').drop('pickup_latitude').drop('dropoff_latitude')\
    .drop('dropoff_longitude').drop('tip_class').drop('total_amount').drop('tolls_amount').drop('mta_tax')\
    .drop('direct_distance').drop('surcharge')\
    .filter("passenger_count > 0 and passenger_count < 8 AND payment_type in ('CSH', 'CRD') \
    AND tip_amount >= 0 AND tip_amount < 30 AND fare_amount >= 1 AND fare_amount < 150 AND trip_distance > 0 \
    AND trip_distance < 100 AND trip_time_in_secs > 30 AND trip_time_in_secs < 7200" )

## REGISTER DATA-FRAME AS A TEMP-TABLE IN SQL-CONTEXT
taxi_df_valid_cleaned.createOrReplaceTempView("taxi_valid")

### CREATE FOUR BUCKETS FOR TRAFFIC TIMES
sqlStatement = """ SELECT *, CASE
     WHEN (pickup_hour <= 6 OR pickup_hour >= 20) THEN "Night" 
     WHEN (pickup_hour >= 7 AND pickup_hour <= 10) THEN "AMRush" 
     WHEN (pickup_hour >= 11 AND pickup_hour <= 15) THEN "Afternoon"
     WHEN (pickup_hour >= 16 AND pickup_hour <= 19) THEN "PMRush"
    END as TrafficTimeBins
    FROM taxi_valid
"""
taxi_df_valid_with_newFeatures = sqlContext.sql(sqlStatement)

## APPLY THE SAME TRANSFORATION ON THIS DATA AS ORIGINAL TRAINING DATA
# DEFINE THE TRANSFORMATIONS THAT NEEDS TO BE APPLIED TO SOME OF THE FEATURES
sI1 = StringIndexer(inputCol="vendor_id", outputCol="vendorIndex");
sI2 = StringIndexer(inputCol="rate_code", outputCol="rateIndex");
sI3 = StringIndexer(inputCol="payment_type", outputCol="paymentIndex");
sI4 = StringIndexer(inputCol="TrafficTimeBins", outputCol="TrafficTimeBinsIndex");

# APPLY TRANSFORMATIONS
encodedFinalValid = Pipeline(stages=[sI1, sI2, sI3, sI4]).fit(taxi_df_valid_with_newFeatures).transform(taxi_df_valid_with_newFeatures)

###################################################################################################################
## LOAD SAVED MODEL, SCORE VALIDATION DATA, AND SAVE PREDICTIONS
###################################################################################################################
CVDirfilename = "wasb:///user/remoteuser/NYCTaxi/Models/CV_RandomForestRegressionModel_02-13-2017-1486959163"
savedModel = PipelineModel.load(CVDirfilename)
predictions = savedModel.transform(encodedFinalValid)
outDF = predictions.select("label","prediction")
outFile = "wasb:///user/remoteuser/NYCTaxi/Outputs/CVRandomForest_RegValidationDataPredictions.csv"
outDF.write.format("com.databricks.spark.csv").options(header=True).mode('overwrite').save(outFile)
###################################################################################################################