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


###########################################
## SPECIFY BASE HDFS DIRECTORY
###########################################
fullDataDir <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubset"

###########################################
## READ IN FILE
###########################################
df <- read.df(fullDataDir, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
cache(df)
printSchema(df)

########################################### 
## CREATE GLM MODEL
###########################################
model <- SparkR::glm(tip_amount ~ payment_type + pickup_hour + fare_amount + passenger_count + 
                       trip_distance + trip_time_in_secs + TrafficTimeBins, 
                       data = df, family = "gaussian", epsilon = 1e-05, maxit = 10)

########################################### 
## PREDICT ON A DATAFRAME
###########################################
predictions <- SparkR::predict(model, newData = df)
predfilt <- SparkR::select(predictions, c("label","prediction"))

###########################################
## SAVE MODEL
###########################################
modelPath = "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMforOper"
write.ml(model, modelPath) 

###########################################
## CONVERT SPARK DATAFRAME TO LOCAL DATAFRAME
###########################################
#df_local <- SparkR::collect(predfilt)

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
  
  ## Read a df
  df <- read.df(input, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
  ## Load a model
  model <- SparkR::read.ml(modelfile)

  ## Predict and select relevant columns
  predictions <- SparkR::predict(model, newData = df)
  predfilt <- SparkR::select(predictions, c("label","prediction"))

  write.df(predfilt, path = output, source = "com.databricks.spark.csv", mode = "overwrite")
  
  sampledpredfilt <- head(SparkR::sample(predfilt, FALSE, 0.01, 1234), 10)
  
  # Return sampled 10 rows of the prediction data-frame
  return(sampledpredfilt)

  sparkR.stop()
}

###############################################################
## Define file paths and test on HDI server
###############################################################
modelfile <- "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMforOper"
input <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubset"
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
  password = "Strata2017@SJC",
  session = FALSE
)
listServices()

################################################################
## CREATE A WEB SERVICE WTIH VERSION NUMBER
################################################################
version <- "v0.0.1"
#deleteService("scoring_string_input", version);
api_string <- publishService(
  "scoring_input_files",
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
api_1 <- getService("scoring_input_files", version)

modelfile <- "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMforOper"
input <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubset"
output <- "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMPredictions"

result_1 <- api_1$web_scoring(
  modelfile = modelfile,
  input = input,
  output = output
)
################################################################
## END
################################################################

sparkR.stop()
#deleteService("scoring_input_files", version)
