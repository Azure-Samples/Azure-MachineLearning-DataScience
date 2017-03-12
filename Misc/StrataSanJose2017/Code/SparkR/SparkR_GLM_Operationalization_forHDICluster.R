###########################################
# LOAD LIBRARIES FROM SPECIFIED PATH
###########################################
Sys.setenv(SPARK_HOME = "/usr/hdp/current/spark2-client")
list.files(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)

###########################################
# CREATE SPARK CONTEXT
###########################################
sc <- sparkR.session(
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)
SparkR::setLogLevel("OFF")

###########################################
## DEFINE A FUNCTION FOR WEB-SERVICE SCORING
###########################################
web_scoring <- function(modelfile, input, output) {
  
  Sys.setenv(SPARK_HOME = "/usr/hdp/current/spark2-client")
  list.files(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
  .libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
  library(SparkR)
  sc <- sparkR.session(
    sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
  )
  SparkR::setLogLevel("OFF")
  
  ## Read a df
  df <- read.df(input, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
  ## Load a model
  model <- SparkR::read.ml(modelfile)

  ## Predict and select relevant columns
  predictions <- SparkR::predict(model, newData = df)
  predfilt <- SparkR::select(predictions, c("label","prediction"))

  write.df(predfilt, path = output, source = "com.databricks.spark.csv", mode = "overwrite")
  
  sampledpredfilt <- head(SparkR::sample(predfilt, FALSE, 0.01, 1234), 10)
  

  sparkR.stop()
  
  # Return sampled 10 rows of the prediction data-frame
  return(sampledpredfilt)

}

###############################################################
## Define file paths and test on HDI server
###############################################################
modelfile <- "/HdiSamples/HdiSamples/NYCTaxi/SparkGlmModel"
input <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubsetSampled"
output <- "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMPredictions"
web_scoring (modelfile, input, output)

################################################################
## LOGIN TO SERVER AND LIST ANY EXISTING WEB SERVICES
################################################################
library(mrsdeploy)
#ssh -L localhost:12800:localhost:12800 remoteuser@DebrajSpark2-ed-ssh.azurehdinsight.net
remoteLogin(
  "http://127.0.0.1:12800",
  username = "admin",
  password = "",
  session = FALSE
)
listServices()

################################################################
## CREATE A WEB SERVICE WTIH VERSION NUMBER
################################################################
version <- "v0.0.1"
#deleteService("scoring_input_files2", version);
api_string <- publishService(
  "scoring_input_files2",
  code = web_scoring,
  inputs = list(modelfile = "character",
                input = "character",
                output = "character"),
  v = version
)
listServices()

################################################################
## CALL WEB SERVICE
################################################################
version <- "v0.0.1"
api_1 <- getService("scoring_input_files2", version)

modelfile <- "/HdiSamples/HdiSamples/NYCTaxi/SparkGlmModel"
input <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubsetSampled"
output <- "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMPredictions"

result_1 <- api_1$web_scoring(
  modelfile = modelfile,
  input = input,
  output = output
)

result_1$success

system("hadoop fs -ls /HdiSamples/HdiSamples/NYCTaxi/SparkRGLMPredictions")

################################################################
## END
################################################################

sparkR.stop()data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAkAAAAJCAYAAADgkQYQAAAAMElEQVR42mNgIAXY2Nj8x8cHC8AwMl9XVxe3QqwKcJmIVwFWhehW4LQSXQCnm3ABAHD6MDrmRgfrAAAAAElFTkSuQmCC
#deleteService("scoring_input_files", version)










#################################################################
#################################################################
## ADDITIONAL CODE FOR MODEL CREATION AND SAVING
#################################################################
#################################################################


###########################################
## READ IN FILE, SAMPLE AND PARTITION
###########################################
fullDataDir <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubset"
df <- read.df(fullDataDir, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
dfSampled <- SparkR::sample(df, withReplacement = FALSE, fraction = 0.01, seed = 123)
SparkR::write.parquet(dfSampled, "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubsetSampled")
cache(dfSampled); count(dfSampled)
printSchema(dfSampled)

########################################### 
## CREATE GLM MODEL
###########################################
sampledDataDir <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubsetSampled"
df <- read.df(sampledDataDir, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
model <- SparkR::spark.glm(tip_amount ~ payment_type + pickup_hour + 
                             fare_amount + passenger_count + trip_distance + 
                             trip_time_in_secs + TrafficTimeBins, 
                           data = df, family = "gaussian", 
                           tol = 1e-05, maxIter = 10)

###########################################
## SAVE MODEL
###########################################
modelPath = "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMforOper"
write.ml(model, modelPath) 

########################################### 
## PREDICT ON A DATAFRAME
###########################################
#predictions <- SparkR::predict(model, newData = dfSampled)
#predfilt <- SparkR::select(predictions, c("label","prediction"))
#df_local <- SparkR::collect(predfilt)
