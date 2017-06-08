setwd("/home/remoteuser/code/2-mrsdeploy-on-DSVM")
source("SetComputeContext.r")

.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)

sparkEnvir <- list(spark.executor.instances = '10',
                   spark.yarn.executor.memoryOverhead = '8000')

sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)

sqlContext <- sparkRSQL.init(sc)

airPath <- file.path(fullDataDir, "AirlineSubsetCsv")

# create a SparkR DataFrame for the airline data
airDF <- read.df(sqlContext, airPath, source = "com.databricks.spark.csv", 
                 header = "true", inferSchema = "true")

################################################
# Data Cleaning and Transformation
################################################

airDF <- SparkR::rename(airDF,
                        ArrDel15 = airDF$ARR_DEL15,
                        Year = airDF$YEAR,
                        Month = airDF$MONTH,
                        DayofMonth = airDF$DAY_OF_MONTH,
                        DayOfWeek = airDF$DAY_OF_WEEK,
                        Carrier = airDF$UNIQUE_CARRIER,
                        OriginAirportID = airDF$ORIGIN_AIRPORT_ID,
                        DestAirportID = airDF$DEST_AIRPORT_ID,
                        CRSDepTime = airDF$CRS_DEP_TIME,
                        CRSArrTime =  airDF$CRS_ARR_TIME
)

# Select desired columns from the flight data. 
varsToKeep <- c("ArrDel15", "Year", "Month", "DayofMonth", "DayOfWeek", "Carrier", "OriginAirportID", "DestAirportID", "CRSDepTime", "CRSArrTime")
airDF <- select(airDF, varsToKeep)

# Round down scheduled departure time to full hour.
airDF$CRSDepTime <- floor(airDF$CRSDepTime / 100)


################################################
# Output to CSV
################################################

# Increase numCSVs when working with larger data
# on a larger cluster
numCSVs <- 2 # write.df below will produce this many CSV files
airDF <- repartition(airDF, numCSVs)

# write result to directory of CSVs
write.df(airDF, file.path(fullDataDir, "airDFCsvSubset"), "com.databricks.spark.csv", "overwrite", header = "true")

# We can shut down the SparkR Spark context now
sparkR.stop()

# remove non-data files
if (is(rxOptions()$fileSystem, "RxHdfsFileSystem")){
  rxHadoopRemove(file.path(fullDataDir, "airDFCsvSubset/_SUCCESS"))
} else{
  file.remove(Sys.glob(file.path(dataDir, "airDFCsvSubset/.*.crc")))
  file.remove(Sys.glob(file.path(dataDir, "airDFCsvSubset/_SUCCESS")))
}

################################################
# Import to compressed, binary XDF format
################################################

colInfo <- list(
  ArrDel15 = list(type="numeric"),
  Year = list(type="factor"),
  Month = list(type="factor"),
  DayofMonth = list(type="factor"),
  DayOfWeek = list(type="factor"),
  Carrier = list(type="factor"),
  OriginAirportID = list(type="factor"),
  DestAirportID = list(type="factor"),
  CRSDepTime = list(type="integer"),
  CRSArrTime = list(type="integer")
)

airDFTxt <- RxTextData(file.path(dataDir, "airDFCsvSubset"),
                       colInfo = colInfo)

finalData <- RxXdfData(file.path(dataDir, "airDFXDFSubset"))

# For local compute context, skip the following line
startRxSpark()

rxImport(inData = airDFTxt, finalData, overwrite = TRUE)

system('hadoop fs -ls /user/RevoShare/remoteuser/Data')

rxGetInfo(finalData, getVarInfo = T)


################################################
# Split out Training and Test Datasets
################################################


finalData <- RxXdfData(file.path(dataDir, "airDFXDFSubset"))


# split out the training data
trainDS <- RxXdfData( file.path(dataDir, "finalDataTrainSubset" ))

rxDataStep( inData = finalData, outFile = trainDS,
            rowSelection = ( Year != 2012 ), overwrite = T )

# split out the testing data
testDS <- RxXdfData( file.path(dataDir, "finalDataTestSubset" ))

rxDataStep( inData = finalData, outFile = testDS,
            rowSelection = ( Year == 2012 ), overwrite = T )


# system('hadoop fs -ls /user/RevoShare/remoteuser/Data')

################################################
# Train and Test a Logistic Regression model
################################################

formula <- as.formula(ArrDel15 ~ Month + DayofMonth + DayOfWeek + Carrier + OriginAirportID + 
                        DestAirportID + CRSDepTime + CRSArrTime)

# Use the scalable rxLogit() function
logitModel <- rxLogit(formula, data = trainDS)

options(max.print = 100)
base::summary(logitModel)

# Predict over test data (Logistic Regression).
logitPredict <- RxXdfData(file.path(dataDir, "logitPredictSubset"))

# Use the scalable rxPredict() function
rxPredict(logitModel, data = testDS, outData = logitPredict,
          extraVarsToWrite = c("ArrDel15"),
          type = 'response', overwrite = TRUE)

# Calculate ROC and Area Under the Curve (AUC).
logitRoc <- rxRoc("ArrDel15", "ArrDel15_Pred", logitPredict)
logitAuc <- rxAuc(logitRoc)

plot(logitRoc)

save(logitModel, file = "logitModelSubset.RData")

# For local compute context, skip the following line
rxSparkDisconnect(rxGetComputeContext())

