# First, we set up the preliminaries
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))

library(SparkR)

sparkEnvir <- list(spark.executor.instances = '70',
                   spark.driver.memory = '4g',
                   spark.yarn.executor.memoryOverhead = '8000'
)

# We initialize SparkR
tSparkRInit <- system.time(
  sc <- sparkR.init(
    sparkEnvir = sparkEnvir,
    sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
  )
)


# We set up the SQL context
sqlContext <- sparkRSQL.init(sc)

# We locate our data
container <- "wasb://nyctaxi@yunzhuuscenbigds.blob.core.windows.net"
dataPath <- "yellow5a" #2009 - 2014, 170.9 GB size
fullPath <- file.path(container, dataPath)

# We now create a SparkR DataFrame
tReadDf <- system.time(
  df <- read.df(sqlContext, fullPath, source = "com.databricks.spark.csv", 
                header = "true", inferSchema = "true")
)

# We identify the names of the columns ...
names_timing <- system.time(
  print(names(df))
)
names_timing

# ... and then the schema itself.
schema_timing <- system.time(
  printSchema(df)
)
schema_timing

# Now, we call it a table just like in an RDBMS
registerTempTable(df, "taxidata")
cacheTable(sqlContext, "taxidata")

# Now for the first SQL. How many records do we have?
record_count_timing <- system.time(
record_count <- sql(sqlContext, "SELECT COUNT(*) FROM taxidata")
)
record_count_timing

# Only when we ask for the results is the SQL actually executed.
count_of_records_timing <- system.time(
  count_of_records <- head(record_count)
)
count_of_records
count_of_records_timing

# Now, for something more interesting.
# How many trips did people make each day and how did they pay?
trip_stats_by_day <- sql(sqlContext, "select year(Trip_Pickup_DateTime) as  year, month(Trip_Pickup_DateTime) as month, 
                         day(Trip_Pickup_DateTime) as day, Payment_Type, count(1) as trips from taxidata group by 
                         year(Trip_Pickup_DateTime), month(Trip_Pickup_DateTime), day(Trip_Pickup_DateTime), Payment_Type")
tsbd_time <- system.time(tsbd <- head(trip_stats_by_day, nrow(trip_stats_by_day)))
head(tsbd)
library(ggmap);
# Plot without cleaning up the different payment types
ggplot(data=tsbd, aes(year + month/12, trips)) + geom_point(aes(color=Payment_Type)) + geom_smooth(aes(color=Payment_Type))
unique(tsbd$Payment_Type) # How many kinds do we have? Turns out we have some junk.
check_pmt_type <- sql(sqlContext, "select Payment_Type, count(1) from taxidata group by Payment_Type")
head(check_pmt_type, nrow(check_pmt_type))
# We now try and homogenize, that is, clean up the values
tsbd$Payment_Type[tsbd$Payment_Type == "Cash"] <- "CSH"
tsbd$Payment_Type[tsbd$Payment_Type == "CASH"] <- "CSH"
tsbd$Payment_Type[tsbd$Payment_Type == "Credit"] <- "CRD"
tsbd$Payment_Type[tsbd$Payment_Type == "CREDIT"] <- "CRD"
tsbd$Payment_Type[tsbd$Payment_Type == "No Charge"] <- "NOC"
tsbd$Payment_Type[tsbd$Payment_Type == "Dispute"] <- "DIS"
tsbd$Payment_Type[tsbd$Payment_Type == " payment_type"] <- "PMT_TYPE"
tsbd$Payment_Type[tsbd$Payment_Type == "payment_type"] <- "PMT_TYPE"
unique(tsbd$Payment_Type) # We check again ... all good.
# Plot after cleaning up the payment types
ggplot(data=tsbd, aes(year + month/12, trips)) + geom_point(aes(color=Payment_Type)) + geom_smooth(aes(color=Payment_Type))

# Now, for the mapping of the rides; first we get the map
nyc_geocode <- geocode("New York City")
nyc_map14 <- get_map(location=c(nyc_geocode$lon, nyc_geocode$lat), zoom=14, source="osm")
nyc_map13 <- get_map(location=c(nyc_geocode$lon, nyc_geocode$lat), zoom=13, source="osm")
nyc_map12 <- get_map(location=c(nyc_geocode$lon, nyc_geocode$lat), zoom=12, source="osm")
nyc_map11 <- get_map(location=c(nyc_geocode$lon, nyc_geocode$lat), zoom=11, source="osm")
nyc_map10 <- get_map(location=c(nyc_geocode$lon, nyc_geocode$lat), zoom=10, source="osm")

trips_2014_June_18_8am <- sql(sqlContext, "select * from taxidata where hour(Trip_Pickup_DateTime) = 8 and day(Trip_Pickup_DateTime) = 18 and month(Trip_Pickup_DateTime) = 6 and year(Trip_Pickup_DateTime) = 2014")
trips_2014_June_18_8am <- as.data.frame(trips_2014_June_18_8am)
trips_2014_June_18_8am$Passenger_Count <- as.numeric(trips_2014_June_18_8am$Passenger_Count)
trips_2014_June_18_8am$Fare_Amt <- as.numeric(trips_2014_June_18_8am$Fare_Amt)
trips_2014_June_18_8am$Start_Lon <- as.numeric(trips_2014_June_18_8am$Start_Lon)
trips_2014_June_18_8am$Start_Lat <- as.numeric(trips_2014_June_18_8am$Start_Lat)
trips_2014_June_18_8am$End_Lon <- as.numeric(trips_2014_June_18_8am$End_Lon)
trips_2014_June_18_8am$End_Lat <- as.numeric(trips_2014_June_18_8am$End_Lat)
trips_2014_June_18_8am$Trip_Distance <- as.numeric(trips_2014_June_18_8am$Trip_Distance)
#ggmap(nyc_map12) + geom_point(data=trips_2014_June_18_8am, aes(Start_Lon, Start_Lat))

trips_2014_June_18_6pm <- sql(sqlContext, "select * from taxidata where hour(Trip_Pickup_DateTime) = 18 and day(Trip_Pickup_DateTime) = 18 and month(Trip_Pickup_DateTime) = 6 and year(Trip_Pickup_DateTime) = 2014")
trips_2014_June_18_6pm <- as.data.frame(trips_2014_June_18_6pm)
trips_2014_June_18_6pm$Passenger_Count <- as.numeric(trips_2014_June_18_6pm$Passenger_Count)
trips_2014_June_18_6pm$Fare_Amt <- as.numeric(trips_2014_June_18_6pm$Fare_Amt)
trips_2014_June_18_6pm$Start_Lon <- as.numeric(trips_2014_June_18_6pm$Start_Lon)
trips_2014_June_18_6pm$Start_Lat <- as.numeric(trips_2014_June_18_6pm$Start_Lat)
trips_2014_June_18_6pm$End_Lon <- as.numeric(trips_2014_June_18_6pm$End_Lon)
trips_2014_June_18_6pm$End_Lat <- as.numeric(trips_2014_June_18_6pm$End_Lat)
trips_2014_June_18_6pm$Trip_Distance <- as.numeric(trips_2014_June_18_6pm$Trip_Distance)
#ggmap(nyc_map12) + geom_point(data=trips_2014_June_18_6pm, aes(Start_Lon, Start_Lat))

# Between 8 AM and 9 AM, where do they start and where do they end?
#ggmap(nyc_map13) + geom_point(data=trips_2014_June_18_8am[trips_2014_June_18_8am$Trip_Distance > 1,], aes(Start_Lon, Start_Lat), color="red", alpha=0.1) + geom_point(data=trips_2014_June_18_8am[trips_2014_June_18_8am$Trip_Distance > 1,], aes(End_Lon, End_Lat), color="blue", alpha=0.1)
# Between 6 PM and 7 PM, where do they start and where do they end?
#ggmap(nyc_map13) + geom_point(data=trips_2014_June_18_6pm[trips_2014_June_18_6pm$Trip_Distance > 1,], aes(Start_Lon, Start_Lat), color="red", alpha = 0.1) + geom_point(data=trips_2014_June_18_6pm[trips_2014_June_18_6pm$Trip_Distance > 1,], aes(End_Lon, End_Lat), color="blue", alpha = 0.1)

# Net Flux in grid points
morning_efflux <- sql(sqlContext, "
select lon, lat, sum(flux) as net_flux from
(select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) flux
from taxidata
          where hour(Trip_Pickup_DateTime) = 8 and day(Trip_Pickup_DateTime) = 18 and 
          month(Trip_Pickup_DateTime) = 6 and year(Trip_Pickup_DateTime) = 2014
          group by round(Start_Lon, 3), round(Start_Lat, 3)
union all 
select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) * -1 flux
from taxidata
           where hour(Trip_Dropoff_DateTime) = 8 and day(Trip_Dropoff_DateTime) = 18 and 
           month(Trip_Dropoff_DateTime) = 6 and year(Trip_Dropoff_DateTime) = 2014
           group by round(Start_Lon, 3), round(Start_Lat, 3)
) piecewise_flux
  group by lon, lat")
morning_efflux <- as.data.frame(morning_efflux)
ggmap(nyc_map12) + geom_point(data=morning_efflux, aes(lon, lat, color=net_flux), alpha = 0.5, 
) + scale_color_continuous(low="blue", high="gold")
#ggmap(nyc_map11) + geom_point(data=morning_efflux, aes(lon, lat, color=net_flux), alpha = 0.5, 
#                              ) + scale_color_continuous(low="blue", high="gold")

evening_efflux <- sql(sqlContext, "
select lon, lat, sum(flux) as net_flux from
(select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) flux
from taxidata
          where hour(Trip_Pickup_DateTime) = 18 and day(Trip_Pickup_DateTime) = 18 and 
          month(Trip_Pickup_DateTime) = 6 and year(Trip_Pickup_DateTime) = 2014
          group by round(Start_Lon, 3), round(Start_Lat, 3)
union all 
select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) * -1 flux
from taxidata
           where hour(Trip_Dropoff_DateTime) = 18 and day(Trip_Dropoff_DateTime) = 18 and 
           month(Trip_Dropoff_DateTime) = 6 and year(Trip_Dropoff_DateTime) = 2014
          group by round(Start_Lon, 3), round(Start_Lat, 3)
) piecewise_flux
  group by lon, lat")
evening_efflux <- as.data.frame(evening_efflux)
ggmap(nyc_map12) + geom_point(data=evening_efflux, aes(lon, lat, color=net_flux), alpha = 0.5, 
) + scale_color_continuous(low="blue", high="gold")
#ggmap(nyc_map11) + geom_point(data=evening_efflux, aes(lon, lat, color=net_flux), alpha = 0.2, 
#                              position=position_jitter(w=0.001, h=0.001)) + scale_color_continuous(low="blue", high="yellow")


late_evening_efflux <- sql(sqlContext, "
select lon, lat, sum(flux) as net_flux from
                      (select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) flux
                      from taxidata
                      where hour(Trip_Pickup_DateTime) = 22 and day(Trip_Pickup_DateTime) = 18 and 
                      month(Trip_Pickup_DateTime) = 6 and year(Trip_Pickup_DateTime) = 2014
                      group by round(Start_Lon, 3), round(Start_Lat, 3)
                      union all 
                      select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) * -1 flux
                      from taxidata
                      where hour(Trip_Dropoff_DateTime) = 22 and day(Trip_Dropoff_DateTime) = 18 and 
                      month(Trip_Dropoff_DateTime) = 6 and year(Trip_Dropoff_DateTime) = 2014
                      group by round(Start_Lon, 3), round(Start_Lat, 3)
                      ) piecewise_flux
                      group by lon, lat")
late_evening_efflux <- as.data.frame(late_evening_efflux)
ggmap(nyc_map12) + geom_point(data=late_evening_efflux, aes(lon, lat, color=net_flux), alpha = 0.5, 
) + scale_color_continuous(low="blue", high="gold")

# OK, now, we generalize it to a function so that we can try out any year, month, day and hour
efflux_year_month_day_hour <- function(year, month, day, hour) {
sqlToRun <- sprintf(" select lon, lat, sum(flux) as net_flux from
                      (select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) flux
        from taxidata
        where hour(Trip_Pickup_DateTime) = %d and day(Trip_Pickup_DateTime) = %d and 
        month(Trip_Pickup_DateTime) = %d and year(Trip_Pickup_DateTime) = %d
        group by round(Start_Lon, 3), round(Start_Lat, 3)
        union all 
        select round(Start_Lon, 3) as lon, round(Start_Lat, 3) as lat, count(1) * -1 flux
        from taxidata
        where hour(Trip_Dropoff_DateTime) = %d and day(Trip_Dropoff_DateTime) = %d and 
        month(Trip_Dropoff_DateTime) = %d and year(Trip_Dropoff_DateTime) = %d
        group by round(Start_Lon, 3), round(Start_Lat, 3)
        ) piecewise_flux
        group by lon, lat", hour, day, month, year, hour, day, month, year)
  efflux_that_hour <- sql(sqlContext, sqlToRun)
  efflux_that_hour <- as.data.frame(efflux_that_hour)
  tfcmap <- ggmap(nyc_map12) + geom_point(data=efflux_that_hour, aes(lon, lat, color=net_flux), alpha = 0.5 
) + scale_color_gradient(low="blue", high="gold") + ggtitle(sprintf("Year: %d Month: %d Day: %d Hour: %d", year, month, day, hour))
  tfcmap
  }


#ggmap(nyc_map11) + geom_point(data=evening_efflux, aes(lon, lat, color=net_flux), alpha = 0.2, 
#                              position=position_jitter(w=0.001, h=0.001)) + scale_color_continuous(low="blue", high="yellow")


# Record count
record_count_time <- system.time(
  record_count_res <- sql(sqlContext, "select count(*) from taxidata")
)
head(record_count_res);
record_count_time

#sparkR.stop()
