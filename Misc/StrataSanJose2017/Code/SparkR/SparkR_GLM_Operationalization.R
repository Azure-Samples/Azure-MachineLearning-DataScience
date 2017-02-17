###########################################
# LOAD LIBRARIES FROM SPECIFIED PATH
###########################################
Sys.setenv(YARN_CONF_DIR="/opt/hadoop/current/etc/hadoop", HADOOP_HOME="/opt/hadoop/current", 
           JAVA_HOME = "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.111-1.b15.el7_2.x86_64",
           SPARK_HOME = "/dsvm/tools/spark/current",
           PATH=paste0(Sys.getenv("PATH"),":/opt/hadoop/current/bin:/dsvm/tools/spark/current/bin") )

list.files(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)

###########################################
# CREATE SPARK CONTEXT
###########################################
sparkEnvir <- list(spark.executor.instance = '4', spark.yarn.executor.memoryOverhead = '8000')
sc <- sparkR.session(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)


###########################################
## SPECIFY BASE HDFS DIRECTORY
###########################################
fullDataDir <- "/user/RevoShare/remoteuser/Data/NYCjoinedParquetSubset"

###########################################
## READ IN FILE
###########################################
df <- read.df(fullDataDir, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
cache(df)
printSchema(df)

########################################### 
## CREATE GLM MODEL
###########################################
model <- SparkR::glm(tip_amount ~ payment_type + pickup_hour + fare_amount + passenger_count + trip_distance + trip_time_in_secs + TrafficTimeBins, 
                     data = df, family = "gaussian", epsilon = 1e-06, maxit = 10)

########################################### 
## PREDICT ON A DATAFRAME
###########################################
predictions <- SparkR::predict(model, newData = df)
predfilt <- SparkR::select(predictions, c("label","prediction"))

###########################################
## SAVE MODEL
###########################################
modelPath = "/user/RevoShare/remoteuser/Models/SparkRGLM"
write.ml(model, modelPath) 

###########################################
## CONVERT SPARK DATAFRAME TO LOCAL DATAFRAME
###########################################
df_local <- SparkR::collect(predfilt)

###########################################
## DEFINE A FUNCTION FOR WEB-SERVICE SCORING
###########################################
web_scoring <- function(modelfile, input, output) {
  
  Sys.setenv(YARN_CONF_DIR="/opt/hadoop/current/etc/hadoop", HADOOP_HOME="/opt/hadoop/current", 
             JAVA_HOME = "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.111-1.b15.el7_2.x86_64",
             SPARK_HOME = "/dsvm/tools/spark/current",
             PATH=paste0(Sys.getenv("PATH"),":/opt/hadoop/current/bin:/dsvm/tools/spark/current/bin"))
  
  list.files(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
  .libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
  library(SparkR)

  sparkEnvir <- list(spark.executor.instance = '4', spark.yarn.executor.memoryOverhead = '8000')
  sc <- sparkR.session(
    sparkEnvir = sparkEnvir,
    sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
  )
  
  ## Read a df
  df <- read.df(input, source = "parquet", header = "true", inferSchema = "true", na.strings = "NA")
  ## Load a model
  model <- read.ml(modelfile)

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
modelfile <- "/user/RevoShare/remoteuser/Models/SparkRGLM"
input <- "/user/RevoShare/remoteuser/Data/NYCjoinedParquetSubset"
output <- "/user/RevoShare/rserve2/Predictions/SparkRGLMPred"
web_scoring (modelfile, input, output)

################################################################
## LOGIN TO SERVER AND LIST ANY EXISTING WEB SERVICES
################################################################
library(mrsdeploy)
#ssh -L localhost:12800:localhost:12800 remoteuser@DebrajSpark2-ed-ssh.azurehdinsight.net
remoteLogin(
  "http://127.0.0.1:12800",
  username = "***",
  password = "****",
  session = FALSE
)
listServices()

################################################################
## CREATE A WEB SERVICE WTIH VERSION NUMBER
################################################################
version <- "v1.1.21"
#deleteService("scoring_string_input", version);
api_string <- publishService(
  "scoring_string_input",
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
api_1 <- getService("scoring_string_input", version)

modelfile <- "/user/RevoShare/remoteuser/Models/SparkRGLM"
input <- "/user/RevoShare/remoteuser/Data/NYCjoinedParquetSubset"
output <- "/user/RevoShare/rserve2/Predictions/SparkRGLMPred2"

result_1 <- api_1$web_scoring(
  modelfile = modelfile,
  input = input,
  output = output
)
################################################################
## END
################################################################