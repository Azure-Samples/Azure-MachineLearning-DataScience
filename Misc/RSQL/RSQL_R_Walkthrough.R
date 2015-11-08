# PreRequisites: You have installed Revolution R Enterprise 7.5.0 or higher on the machine and SQL Server 2016 CTP3 or higher on the database server
# install required R libraries for this walkthrough. 
# NOTE: You may delete the install.packages lines after first time you run the script on a machine
install.packages('ggmap')
install.packages('mapproj')
install.packages('ROCR')
install.packages('RODBC')

library(RevoScaleR)
# connection string
# currently we require SQL authentication to run R in SQL Server Context
connStr <- "Driver=SQL Server;Server=<your_server_name.somedomain.com>;Database=<Your_Database_Name>;Uid=<Your_User_Name>;Pwd=<Your_Password>"

# set ComputeContext. Needs a temp directory path to serialize R objects back and forth
sqlShareDir <- paste("C:\\AllShare\\",Sys.getenv("USERNAME"),sep="")
sqlWait <- TRUE
sqlConsoleOutput <- FALSE
cc <- RxInSqlServer(connectionString = connStr, shareDir = sqlShareDir, 
                    wait = sqlWait, consoleOutput = sqlConsoleOutput)
rxSetComputeContext(cc)

#define a DataSource (from a select query) to be used to explore the data and generate features from
sampleDataQuery <- "select top 1000 tipped, fare_amount, passenger_count,trip_time_in_secs,trip_distance, 
    pickup_datetime, dropoff_datetime, pickup_longitude, pickup_latitude, dropoff_longitude,  
    dropoff_latitude from nyctaxi_joined_1_percent"


inDataSource <- RxSqlServerData(sqlQuery = sampleDataQuery, connectionString = connStr, 
                                colClasses = c(pickup_longitude = "numeric", pickup_latitude = "numeric", 
                                               dropoff_longitude = "numeric", dropoff_latitude = "numeric"),
                                rowsPerRead=500)


# summarize the inDataSource
rxGetVarInfo(data = inDataSource)
start.time <- proc.time()
rxSummary(~fare_amount:F(passenger_count), data = inDataSource)
used.time <- proc.time() - start.time
print(paste("It takes CPU Time=", round(used.time[1]+used.time[2],2)," seconds, Elapsed Time=", 
            round(used.time[3],2), " seconds to summarize the inDataSource.", sep=""))

# define a function in open source R to calculate the direct distance between pickup and dropoff as a new feature 
# Use Haversine Formula: https://en.wikipedia.org/wiki/Haversine_formula
env <- new.env()

env$ComputeDist <- function(pickup_long, pickup_lat, dropoff_long, dropoff_lat){
  R <- 6371/1.609344 #radius in mile
  delta_lat <- dropoff_lat - pickup_lat
  delta_long <- dropoff_long - pickup_long
  degrees_to_radians = pi/180.0
  a1 <- sin(delta_lat/2*degrees_to_radians)
  a2 <- as.numeric(a1)^2
  a3 <- cos(pickup_lat*degrees_to_radians)
  a4 <- cos(dropoff_lat*degrees_to_radians)
  a5 <- sin(delta_long/2*degrees_to_radians)
  a6 <- as.numeric(a5)^2
  a <- a2+a3*a4*a6
  c <- 2*atan2(sqrt(a),sqrt(1-a))
  d <- R*c
  return (d)
}

#define the featureDataSource to be used to store the features, specify the certain variables as numeric
featureDataSource = RxSqlServerData(table = "features", 
                                    colClasses = c(pickup_longitude = "numeric", pickup_latitude = "numeric", 
                                               dropoff_longitude = "numeric", dropoff_latitude = "numeric",
                                                  passenger_count  = "numeric", trip_distance  = "numeric",
                                                   trip_time_in_secs  = "numeric", direct_distance  = "numeric"),
                                    connectionString = connStr)

# create features (including direct distance)
start.time <- proc.time()
rxDataStep(inData =   inDataSource, outFile = featureDataSource,  overwrite = TRUE, 
                           varsToKeep=c("tipped", "fare_amount", "passenger_count","trip_time_in_secs", 
                                        "trip_distance", "pickup_datetime", "dropoff_datetime", "pickup_longitude",
                                        "pickup_latitude","dropoff_longitude", "dropoff_latitude"),
                           transforms = list(direct_distance=ComputeDist(pickup_longitude, pickup_latitude, dropoff_longitude, 
                                                              dropoff_latitude)),
                           transformEnvir = env, rowsPerRead=500, reportProgress = 3)
used.time <- proc.time() - start.time
print(paste("It takes CPU Time=", round(used.time[1]+used.time[2],2), 
            " seconds, Elapsed Time=", round(used.time[3],2), " seconds to generate features.", sep=""))

# alternatively, create features with SQL query for faster processing time
featureEngineeringQuery = "SELECT tipped, fare_amount, passenger_count,trip_time_in_secs,trip_distance, 
    pickup_datetime, dropoff_datetime, 
    dbo.fnCalculateDistance(pickup_latitude, pickup_longitude,  dropoff_latitude, dropoff_longitude) as direct_distance,
    pickup_latitude, pickup_longitude,  dropoff_latitude, dropoff_longitude
    FROM nyctaxi_joined_1_percent
    tablesample (1 percent) repeatable (98052)
"
featureDataSource = RxSqlServerData(sqlQuery = featureEngineeringQuery, 
                                    colClasses = c(pickup_longitude = "numeric", pickup_latitude = "numeric", 
                                               dropoff_longitude = "numeric", dropoff_latitude = "numeric",
                                                  passenger_count  = "numeric", trip_distance  = "numeric",
                                                   trip_time_in_secs  = "numeric", direct_distance  = "numeric"),
                                    connectionString = connStr)

# summarize the feature table
rxGetVarInfo(data = featureDataSource)

options(jupyter.plot_mimetypes = 'image/png')

# plot fare amount histogram
start.time <- proc.time()
rxHistogram(~fare_amount, data = featureDataSource, title = "Fare Amount Histogram")
used.time <- proc.time() - start.time
print(paste("It takes CPU Time=", round(used.time[1]+used.time[2],2), 
            " seconds, Elapsed Time=", round(used.time[3],2), " seconds to generate histogram.", sep=""))

# plot pickup location on map in SQL Server
# define a function that plots points on a map
mapPlot <- function(featureDataSource, googMap){
    library(ggmap)
    library(mapproj)

# Open Source R functions require data to be brought back in memory into data frames. Use rxImport to bring in data. 
# Remember: This whole function is run in the SQL Server Context.
    ds <- rxImport(featureDataSource)

    p<-ggmap(googMap)+
    geom_point(aes(x = pickup_longitude, y =pickup_latitude ), 
                      data=ds, alpha =.5, color="darkred", size = 1.5)

    return(list(myplot=p))
}

library(ggmap)
library(mapproj)
# Get the map with Times Square, NY as the center. This is run on the R Client
gc <- geocode("Times Square", source = "google")
googMap <- get_googlemap(center = as.numeric(gc), zoom = 12, maptype = 'roadmap', color = 'color')
# Run the points plotting on SQL server. Passing in the map data as arg to remotely executed function. 
# The points are in the database and will be plotted on the map
myplots <- rxExec(mapPlot, featureDataSource, googMap, timesToRun = 1)
plot(myplots[[1]][["myplot"]])


# build classification model to predict tipped or not
system.time(logitObj <- rxLogit(tipped ~ passenger_count + trip_distance + trip_time_in_secs + direct_distance, data = featureDataSource))
summary(logitObj)

# predict and write the prediction results back to SQL Server table
scoredOutput <- RxSqlServerData(
  connectionString = connStr,
  table = "taxiScoreOutput"
)

rxPredict(modelObject = logitObj, data = featureDataSource, outData = scoredOutput, 
                   predVarNames = "Score", type = "response", writeModelVars = TRUE, overwrite = TRUE)


# plot ROC curve from SQL Context
rxRocCurve( "tipped", "Score", scoredOutput)

# Plot accuracy vs threshold
# We demonstrate how to do it on the client using Open source R library (ROCR)
# NOTE: The non Revolution R Enterprise functions ("rx") run locally even if execution context is set to SQL Server
# First of all you need to bring the scored Output data to the client using rxImport
scoredOutput = rxImport(scoredOutput)

library('ROCR')
pred <- prediction(scoredOutput$Score, scoredOutput$tipped)

acc.perf = performance(pred, measure = 'acc')
plot(acc.perf)
ind = which.max( slot(acc.perf, 'y.values')[[1]] )
acc = slot(acc.perf, 'y.values')[[1]][ind]
cutoff = slot(acc.perf, 'x.values')[[1]][ind]

# OPERATIONALIZE THE MODELS NOW
# First, serialize a model and put it into a database table
modelbin <- serialize(logitObj, NULL)
modelbinstr=paste(modelbin, collapse="")

library(RODBC)
conn <- odbcDriverConnect(connStr )

# persist model by calling a stored procedure from SQL
q<-paste("EXEC PersistModel @m='", modelbinstr,"'", sep="")
sqlQuery (conn, q)

#We have already provided and installed two stored procs to call for prediction on this model - PredictTipBatchMode and PredictTipSingleMode
# predict with stored procedure in batch mode. Take a few records that are not part of training data
# NOTE: You need to generate the distance feature when you extract the records to send for prediction in batch mode
input = "N'select top 10 a.passenger_count as passenger_count, 
	a.trip_time_in_secs as trip_time_in_secs,
	a.trip_distance as trip_distance,
	a.dropoff_datetime as dropoff_datetime,  
	dbo.fnCalculateDistance(pickup_latitude, pickup_longitude, dropoff_latitude,dropoff_longitude) as direct_distance 
from
(
	select medallion, hack_license, pickup_datetime, passenger_count,trip_time_in_secs,trip_distance,  
		dropoff_datetime, pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude
	from nyctaxi_joined_1_percent
)a
left outer join
(
select medallion, hack_license, pickup_datetime
from nyctaxi_joined_1_percent
tablesample (1 percent) repeatable (98052)
)b
on a.medallion=b.medallion and a.hack_license=b.hack_license and a.pickup_datetime=b.pickup_datetime
where b.medallion is null
'"
q<-paste("EXEC PredictTipBatchMode @input = ", input, sep="")
sqlQuery (conn, q)

# Call predict on a single observation
q = "EXEC PredictTipSingleMode 1, 2.5, 631, 40.763958,-73.973373, 40.782139,-73.977303 "
sqlQuery (conn, q)
