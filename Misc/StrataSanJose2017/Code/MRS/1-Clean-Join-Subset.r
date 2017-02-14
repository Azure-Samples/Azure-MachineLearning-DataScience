setwd("/home/remoteuser/Code/MRS")
source("SetComputeContext.r")

if(Sys.getenv("SPARK_HOME")=="")
{
  Sys.setenv(SPARK_HOME="/dsvm/tools/spark/current")
}

Sys.setenv(YARN_CONF_DIR="/opt/hadoop/current/etc/hadoop", 
           JAVA_HOME = "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.111-1.b15.el7_2.x86_64") 

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

joinedDF5 <- repartition(joinedDF5, 16) # write.df below will produce this many CSVs

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

destData <- RxXdfData(file.path(dataDir, "joined5XDFSubset"))

rxImport(inData = joinedDF5Txt, destData, overwrite = TRUE)

rxGetInfo(destData, getVarInfo = T)
# File name: /user/RevoShare/dev/delayDataLarge/joined5XDFSubset 
# Number of composite data files: 16 
# Number of observations: 1900875 
# Number of variables: 22 
# Number of blocks: 16 
# Compression type: zlib 
# Variable information: 
#   Var 1: ArrDel15, Type: numeric, Low/High: (0.0000, 1.0000)
# Var 2: Year
# 2 factor levels: 2012 2011
# Var 3: Month
# 2 factor levels: 1 2
# Var 4: DayofMonth
# 31 factor levels: 20 27 9 16 23 ... 13 17 4 10 30
# Var 5: DayOfWeek
# 7 factor levels: 5 4 1 3 7 6 2
# Var 6: Carrier
# 17 factor levels: EV AA WN AS OO ... UA F9 XE HA VX
# Var 7: OriginAirportID
# 295 factor levels: 10397 11298 14107 13232 12266 ... 13139 15048 14955 11699 10728
# Var 8: DestAirportID
# 295 factor levels: 10135 10140 10146 10208 10257 ... 13139 14512 14955 10728 10577
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
