setwd("/home/remoteuser/Code/MRS")
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
weatherPath <- file.path(fullDataDir, "WeatherSubsetCsv")

# create a SparkR DataFrame for the airline data

airDF <- read.df(sqlContext, airPath, source = "com.databricks.spark.csv", 
                 header = "true", inferSchema = "true")

# Create a SparkR DataFrame for the weather data

weatherDF <- read.df(sqlContext, weatherPath, source = "com.databricks.spark.csv", 
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

# Average weather readings by hour
weatherDF <- agg(groupBy(weatherDF, "AdjustedYear", "AdjustedMonth", "AdjustedDay", "AdjustedHour", "AirportID"), Visibility="avg",
                 DryBulbCelsius="avg", DewPointCelsius="avg", RelativeHumidity="avg", WindSpeed="avg", Altimeter="avg"
)

weatherDF <- SparkR::rename(weatherDF,
                    Visibility = weatherDF$'avg(Visibility)',
                    DryBulbCelsius = weatherDF$'avg(DryBulbCelsius)',
                    DewPointCelsius = weatherDF$'avg(DewPointCelsius)',
                    RelativeHumidity = weatherDF$'avg(RelativeHumidity)',
                    WindSpeed = weatherDF$'avg(WindSpeed)',
                    Altimeter = weatherDF$'avg(Altimeter)'
)

#######################################################
# Join airline data with weather at Origin Airport
#######################################################

joinedDF <- SparkR::join(
  airDF,
  weatherDF,
  airDF$OriginAirportID == weatherDF$AirportID &
    airDF$Year == weatherDF$AdjustedYear &
    airDF$Month == weatherDF$AdjustedMonth &
    airDF$DayofMonth == weatherDF$AdjustedDay &
    airDF$CRSDepTime == weatherDF$AdjustedHour,
  joinType = "left_outer"
)

# Remove redundant columns
vars <- names(joinedDF)
varsToDrop <- c('AdjustedYear', 'AdjustedMonth', 'AdjustedDay', 'AdjustedHour', 'AirportID')
varsToKeep <- vars[!(vars %in% varsToDrop)]
joinedDF1 <- select(joinedDF, varsToKeep)

joinedDF2 <- SparkR::rename(joinedDF1,
                    VisibilityOrigin = joinedDF1$Visibility,
                    DryBulbCelsiusOrigin = joinedDF1$DryBulbCelsius,
                    DewPointCelsiusOrigin = joinedDF1$DewPointCelsius,
                    RelativeHumidityOrigin = joinedDF1$RelativeHumidity,
                    WindSpeedOrigin = joinedDF1$WindSpeed,
                    AltimeterOrigin = joinedDF1$Altimeter
)

#######################################################
# Join airline data with weather at Destination Airport
#######################################################

joinedDF3 <- SparkR::join(
  joinedDF2,
  weatherDF,
  airDF$DestAirportID == weatherDF$AirportID &
    airDF$Year == weatherDF$AdjustedYear &
    airDF$Month == weatherDF$AdjustedMonth &
    airDF$DayofMonth == weatherDF$AdjustedDay &
    airDF$CRSDepTime == weatherDF$AdjustedHour,
  joinType = "left_outer"
)

# Remove redundant columns
vars <- names(joinedDF3)
varsToDrop <- c('AdjustedYear', 'AdjustedMonth', 'AdjustedDay', 'AdjustedHour', 'AirportID')
varsToKeep <- vars[!(vars %in% varsToDrop)]
joinedDF4 <- select(joinedDF3, varsToKeep)

joinedDF5 <- SparkR::rename(joinedDF4,
                    VisibilityDest = joinedDF4$Visibility,
                    DryBulbCelsiusDest = joinedDF4$DryBulbCelsius,
                    DewPointCelsiusDest = joinedDF4$DewPointCelsius,
                    RelativeHumidityDest = joinedDF4$RelativeHumidity,
                    WindSpeedDest = joinedDF4$WindSpeed,
                    AltimeterDest = joinedDF4$Altimeter
)


################################################
# Output to CSV
################################################

# Increase numCSVs when working with larger data
# on a larger cluster
numCSVs <- 2 # write.df below will produce this many CSV files
joinedDF5 <- repartition(joinedDF5, numCSVs)

# write result to directory of CSVs
write.df(joinedDF5, file.path(fullDataDir, "joined5CsvSubset"), "com.databricks.spark.csv", "overwrite", header = "true")

# We can shut down the SparkR Spark context now
sparkR.stop()

# remove non-data files
if (is(rxOptions()$fileSystem, "RxHdfsFileSystem"))
{
  rxHadoopRemove(file.path(fullDataDir, "joined5CsvSubset/_SUCCESS"))
} else
{
  file.remove(Sys.glob(file.path(dataDir, "joined5CsvSubset/.*.crc")))
  file.remove(Sys.glob(file.path(dataDir, "joined5CsvSubset/_SUCCESS")))
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
  RelativeHumidityOrigin = list(type="numeric"),
  AltimeterOrigin = list(type="numeric"),
  DryBulbCelsiusOrigin = list(type="numeric"),
  WindSpeedOrigin = list(type="numeric"),
  VisibilityOrigin = list(type="numeric"),
  DewPointCelsiusOrigin = list(type="numeric"),
  RelativeHumidityDest = list(type="numeric"),
  AltimeterDest = list(type="numeric"),
  DryBulbCelsiusDest = list(type="numeric"),
  WindSpeedDest = list(type="numeric"),
  VisibilityDest = list(type="numeric"),
  DewPointCelsiusDest = list(type="numeric")
)

joinedDF5Txt <- RxTextData(file.path(dataDir, "joined5CsvSubset"),
                           colInfo = colInfo)

finalData <- RxXdfData(file.path(dataDir, "joined5XDFSubset"))

# For local compute context, skip the following line
startRxSpark()

rxImport(inData = joinedDF5Txt, finalData, overwrite = TRUE)

rxGetInfo(finalData, getVarInfo = T)
# File name: /user/RevoShare/remoteuser/Data/joined5XDFSubset 
# Number of composite data files: 2 
# Number of observations: 1900875 
# Number of variables: 22 
# Number of blocks: 4 
# Compression type: zlib 
# Variable information: 
#   Var 1: ArrDel15, Type: numeric, Low/High: (0.0000, 1.0000)
# Var 2: Year
# 2 factor levels: 2011 2012
# Var 3: Month
# 2 factor levels: 2 1
# Var 4: DayofMonth
# 31 factor levels: 1 10 18 2 8 ... 12 4 7 29 5
# Var 5: DayOfWeek
# 7 factor levels: 2 4 3 7 6 5 1
# Var 6: Carrier
# 17 factor levels: EV FL MQ OO WN ... CO F9 B6 VX HA
# Var 7: OriginAirportID
# 295 factor levels: 10397 11697 11298 14869 11292 ... 10165 13139 11699 14955 10728
# Var 8: DestAirportID
# 295 factor levels: 10135 10136 10140 10146 10157 ... 13139 11699 10728 14955 10577
# Var 9: CRSDepTime, Type: integer, Low/High: (0, 23)
# Var 10: CRSArrTime, Type: integer, Low/High: (1, 2400)
# Var 11: RelativeHumidityOrigin, Type: numeric, Low/High: (2.0000, 100.0000)
# Var 12: AltimeterOrigin, Type: numeric, Low/High: (28.3000, 31.1600)
# Var 13: DryBulbCelsiusOrigin, Type: numeric, Low/High: (-46.1000, 32.2000)
# Var 14: WindSpeedOrigin, Type: numeric, Low/High: (0.0000, 48.0000)
# Var 15: VisibilityOrigin, Type: numeric, Low/High: (0.0000, 80.0000)
# Var 16: DewPointCelsiusOrigin, Type: numeric, Low/High: (-41.7000, 23.9000)
# Var 17: RelativeHumidityDest, Type: numeric, Low/High: (2.0000, 100.0000)
# Var 18: AltimeterDest, Type: numeric, Low/High: (28.2500, 31.1600)
# Var 19: DryBulbCelsiusDest, Type: numeric, Low/High: (-46.1000, 31.7000)
# Var 20: WindSpeedDest, Type: numeric, Low/High: (0.0000, 47.6250)
# Var 21: VisibilityDest, Type: numeric, Low/High: (0.0000, 80.0000)
# Var 22: DewPointCelsiusDest, Type: numeric, Low/High: (-43.0000, 24.2000)
