# COPY THIS SCRIPT INTO THE SPARK CLUSTER SO IT CAN BE TRIGGERED WHENEVER WE WANT TO SCORE A FILE BASED ON PREBUILT MODEL
# MODEL CAN BE BUILT USING ONE OF THE TWO EXAMPLE NOTEBOOKS: Simple - Modeling with One Param Set Only.ipynb OR Detailed - Modeling with CV and Param Sweeps.ipynb
# # Scoring wtih Saved ML Models Generated from the Sampled NYC Taxi Trip and Fare Dataset 
# ## Here we show some how to load models that are stored in blobs, and score data-sets with these stored models.
# 
# OBJECTIVE: To use models and files to be scroed, that are stored in blob storage, to produce scored data and save that data to blob storage.

# ## Settting Directory Paths in Mapped Blob Storage Prior to Running
# 
# Where models/files are being saved in the blob, the path needs to be specified properly. Default container which is attached to the Spark cluster can be referenced as: "wasb//".
# 
# Models are saved in: "wasb:///user/remoteuser/NYCTaxi/Models". If this path is not set properly, models will not be loaded for scoring.
# 
# We save scored results in: "wasb:///user/remoteuser/NYCTaxi/ScoredResults". If the path to folder is incorrect, rsutls will not be saved in that folder.

# ### Set directory paths and location of files

# 1. Location of data to be scored
taxi_test_file_loc = "wasb://mllibwalkthroughs@cdspsparksamples.blob.core.windows.net/Data/NYCTaxi/JoinedTaxiTripFare.Point1Pct.Test.tsv";

# 2. Set model storage directory path
modelDir = "wasb:///user/remoteuser/NYCTaxi/Models/"; # The last backslash is needed;

# 3. Set scored result directory path
scoredResultDir = "wasb:///user/remoteuser/NYCTaxi/ScoredResults/"; # The last backslash is needed;

## 4. MODEL FILE LOCATIONS -- REPLACE WITH ***LOCATION*** WHERE YOUR MODEL IS SAVED FROM YOUR JUPYTER NOTEBOOK WHERE MODEL IS BUILT
BoostedTreeRegressionFileLoc = modelDir + "GradientBoostingTreeRegression_2016-04-0116_26_52.098590";

import datetime

# ## Set spark context and import necessary libraries
import pyspark
from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import SQLContext
from pyspark.sql import Row
from pyspark.sql.functions import UserDefinedFunction
from pyspark.sql.types import *
import atexit
from numpy import array
import numpy as np
import datetime

sc = SparkContext(appName="PythonGBNYCPred")
sqlContext = SQLContext(sc)
atexit.register(lambda: sc.stop())

sc.defaultParallelism

# ## Data ingestion: Read in joined 0.1% taxi trip and fare file (as tsv), format and clean data, and create data-frame
## IMPORT FILE FROM PUBLIC BLOB

taxi_test_file = sc.textFile(taxi_test_file_loc)

## GET SCHEMA OF THE FILE FROM HEADER
taxi_header = taxi_test_file.filter(lambda l: "medallion" in l)

## PARSE FIELDS AND CONVERT DATA TYPE FOR SOME FIELDS
taxi_temp = taxi_test_file.subtract(taxi_header).map(lambda k: k.split("\t"))        .map(lambda p: (p[0],p[1],p[2],p[3],p[4],p[5],p[6],int(p[7]),int(p[8]),int(p[9]),int(p[10]),
                        float(p[11]),float(p[12]),p[13],p[14],p[15],p[16],p[17],p[18],float(p[19]),
                        float(p[20]),float(p[21]),float(p[22]),float(p[23]),float(p[24]),int(p[25]),int(p[26])))
    
## GET SCHEMA OF THE FILE FROM HEADER
schema_string = taxi_test_file.first()
fields = [StructField(field_name, StringType(), True) for field_name in schema_string.split('\t')]
fields[7].dataType = IntegerType() #Pickup hour
fields[8].dataType = IntegerType() # Pickup week
fields[9].dataType = IntegerType() # Weekday
fields[10].dataType = IntegerType() # Passenger count
fields[11].dataType = FloatType() # Trip time in secs
fields[12].dataType = FloatType() # Trip distance
fields[19].dataType = FloatType() # Fare amount
fields[20].dataType = FloatType() # Surcharge
fields[21].dataType = FloatType() # Mta_tax
fields[22].dataType = FloatType() # Tip amount
fields[23].dataType = FloatType() # Tolls amount
fields[24].dataType = FloatType() # Total amount
fields[25].dataType = IntegerType() # Tipped or not
fields[26].dataType = IntegerType() # Tip class
taxi_schema = StructType(fields)

## CREATE DATA FRAME
taxi_df_test = sqlContext.createDataFrame(taxi_temp, taxi_schema)

## CREATE A CLEANED DATA-FRAME BY DROPPING SOME UN-NECESSARY COLUMNS & FILTERING FOR UNDESIRED VALUES OR OUTLIERS
taxi_df_test_cleaned = taxi_df_test.drop('medallion').drop('hack_license').drop('store_and_fwd_flag').drop('pickup_datetime')    .drop('dropoff_datetime').drop('pickup_longitude').drop('pickup_latitude').drop('dropoff_latitude')    .drop('dropoff_longitude').drop('tip_class').drop('total_amount').drop('tolls_amount').drop('mta_tax')    .drop('direct_distance').drop('surcharge')    .filter("passenger_count > 0 AND passenger_count < 8 AND payment_type in('CSH','CRD') AND tip_amount >= 0 AND fare_amount > 0")

# #### Creating labeledpoint RDD objects for input into models

from pyspark.mllib.regression import LabeledPoint
from pyspark.mllib.linalg import Vectors
from pyspark.mllib.feature import StandardScaler, StandardScalerModel
from pyspark.mllib.util import MLUtils
from numpy import array

# ONE-HOT ENCODING OF CATEGORICAL TEXT VARIABLES FOR INPUT INTO TREE-BASED MODELS
def parseRowIndexingRegression(line):
    features = np.array([line.paymentIndex, line.vendorIndex, line.rateIndex, line.pickup_hour, line.weekday,
                         line.passenger_count, line.trip_time_in_secs, line.trip_distance, line.fare_amount])
    labPt = LabeledPoint(line.tip_amount, features)
    return  labPt

# ## Feature transformation and data prep for scoring with models
# #### Indexing and one-hot encoding of categorical features

from pyspark.ml.feature import OneHotEncoder, StringIndexer, VectorAssembler, OneHotEncoder, VectorIndexer

stringIndexer = StringIndexer(inputCol="vendor_id", outputCol="vendorIndex")
model = stringIndexer.fit(taxi_df_test_cleaned)
indexed = model.transform(taxi_df_test_cleaned)
encoder = OneHotEncoder(dropLast=False, inputCol="vendorIndex", outputCol="vendorVec")
encoded1 = encoder.transform(indexed)

stringIndexer = StringIndexer(inputCol="rate_code", outputCol="rateIndex")
model = stringIndexer.fit(encoded1)
indexed = model.transform(encoded1)
encoder = OneHotEncoder(dropLast=False, inputCol="rateIndex", outputCol="rateVec")
encoded2 = encoder.transform(indexed)

stringIndexer = StringIndexer(inputCol="payment_type", outputCol="paymentIndex")
model = stringIndexer.fit(encoded2)
indexed = model.transform(encoded2)
encoder = OneHotEncoder(dropLast=False, inputCol="paymentIndex", outputCol="paymentVec")
encodedFinal = encoder.transform(indexed)


# #### Creating labeledpoint RDD objects for input into models

from pyspark.mllib.regression import LabeledPoint
from pyspark.mllib.linalg import Vectors
from pyspark.mllib.feature import StandardScaler, StandardScalerModel
from pyspark.mllib.util import MLUtils
from numpy import array


# ONE-HOT ENCODING OF CATEGORICAL TEXT VARIABLES FOR INPUT INTO TREE-BASED MODELS
def parseRowIndexingRegression(line):
    features = np.array([line.paymentIndex, line.vendorIndex, line.rateIndex, line.pickup_hour, line.weekday,
                         line.passenger_count, line.trip_time_in_secs, line.trip_distance, line.fare_amount])
    labPt = LabeledPoint(line.tip_amount, features)
    return  labPt

################################################
# FOR REGRESSION CLASSIFICATION TRAINING AND TESTING
################################################
indexedTESTreg = encodedFinal.map(parseRowIndexingRegression)

from pyspark.mllib.util import MLUtils

# ### Scoring with saved Gradient Boosting Tree Models, and saving output to blob

from pyspark.mllib.tree import GradientBoostedTrees, GradientBoostedTreesModel

####################################
## REGRESSION: LOAD SAVED MODEL, SCORE AND SAVE RESULTS BACK TO BLOB
####################################
savedModel = GradientBoostedTreesModel.load(sc, BoostedTreeRegressionFileLoc)
predictions = savedModel.predict(indexedTESTreg.map(lambda x: x.features))
predictionAndLabels = indexedTESTreg.map(lambda lp: lp.label).zip(predictions)

# SAVE RESULTS
datestamp = unicode(datetime.datetime.now()).replace(' ','').replace(':','_');
filename = "GradientBoostingTreeRegression_" + datestamp + ".txt";
dirfilename = scoredResultDir + filename;
predictionAndLabels.saveAsTextFile(dirfilename)
