# Using SparkR and sparklyr with 2013 NYCTaxi Data: Data manipulations, modeling, and evaluation
Algorithms and Data Science, Microsoft Data Group  
`r format(Sys.time(), '%B %d, %Y')`  

<hr>
#Introduction
This Markdown document shows the use of <a href="https://spark.apache.org/docs/latest/sparkr.html" target="_blank">SparkR</a> and <a href="http://spark.rstudio.com/index.html" target="_blank">sparklyr</a> packages for data manipulation, and creating machine learning models in spark context. The data used for this exercise is the public NYC Taxi Trip and Fare data-set (2013, December, ~4 Gb, ~13 million rows) available from: http://www.andresmh.com/nyctaxitrips. Data for this exercise can be downloaded from the public blob (see below). The data can be uploaded to the blob (or other storage) attached to your HDInsight cluster (HDFS) and used as input into the scripts shown here.

We use SparkR for data manipulations (e.g. data joining) and sparklyr for creating and evaluating models. Where necessary, small amounts of data is brought to the local data frames for plotting and visualization.
<hr>
<br>

#Using SparkR for data manipulation
SparkR is an R package that provides a light-weight frontend to use Apache Spark from R. In Spark 1.6.2, SparkR provides a distributed data frame implementation that supports operations like selection, filtering, aggregation etc. (similar to R data frames, dplyr) but on large datasets. SparkR also provides limited support for distributed machine learning using MLlib.

<br>

##Creating spark context / connections and loading required packages

```r
###########################################
# CREATE SPARK CONTEXT
###########################################
list.files(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
```

```
## [1] "SparkR"     "sparkr.zip"
```

```r
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
library(SparkR)

sparkEnvir <- list(spark.executor.instance = '10', spark.yarn.executor.memoryOverhead = '8000')
sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)
```

```
## Launching java with spark-submit command /usr/hdp/current/spark-client/bin/spark-submit  --packages com.databricks:spark-csv_2.10:1.3.0 sparkr-shell /tmp/RtmpRyu0Sl/backend_port97002e3a83e8
```

```r
sqlContext <- sparkRSQL.init(sc)

###########################################
# LOAD LIBRARIES FROM SPECIFIED PATH
###########################################
library(rmarkdown)
library(knitr)
library(gridExtra)
library(sparklyr)
library(dplyr)
library(DBI)
library(sparkapi)
library(ggplot2)
###########################################
## CREATE SPARKLYR SPARK CONNECTION
###########################################
sp <- spark_connect(master = "yarn-client")
sqlContextSPR <- sparkRSQL.init(sp)
```
<hr>

##Reading in files from HDFS (csv or parquet format) and manipulate using SQL
Data for this exercise can be downloaded from the public blob locations below: 
<br>
1. Trip (Csv): http://cdspsparksamples.blob.core.windows.net/data/NYCTaxi/KDD2016/trip_data_12.csv
<br>
2. Fare (Csv): http://cdspsparksamples.blob.core.windows.net/data/NYCTaxi/KDD2016/trip_fare_12.csv
<br>
The data can be uploaded to the blob (or other storage) attached to your HDInsight cluster (HDFS) and used as input into the scripts shown here. The csv files can be read into Spark context and saved in parquet format. Once saved in parquet format, data can be read in much more quickly than csv files.

###You can read in raw files in csv or parquet formats. Parquet format files are usually read in much more quickly.

```r
###########################################
# TRIP FILE (CSV format)
###########################################
tripDF <- read.df(sqlContext, "/HdiSamples/HdiSamples/NYCTaxi/Csv/trip_data_12.csv", source = "com.databricks.spark.csv", header = "true", inferSchema = "true")

###########################################
# FARE FILE (parquet format)
###########################################
fareDF <- read.parquet(sqlContext, "/HdiSamples/HdiSamples/NYCTaxi/FareParquetFile")
#fareDF <- read.df(sqlContext, "/HdiSamples/HdiSamples/NYCTaxi/Csv/trip_fare_12.csv", source = "com.databricks.spark.csv", header = "true", inferSchema = "true")
```

###Register tables and join using SQL. 
You can register dataframes as tables in SQLContext and join using multiple columns. The following SQL also filters the data for some outliers.

```r
###########################################
# 1. REGISTER TABLES AND JOIN ON MULTIPLE COLUMNS, FILTER DATA
# 2. REGISTER JIONED TABLE
###########################################
SparkR::registerTempTable(tripDF, "trip");
SparkR::registerTempTable(fareDF, "fare");

trip_fare <-  SparkR::sql(sqlContext, "
  SELECT hour(f.pickup_datetime) as pickup_hour, f.vendor_id, f.fare_amount, 
  f.surcharge, f.tolls_amount, f.tip_amount, f.payment_type, t.rate_code, 
  t.passenger_count, t.trip_distance, t.trip_time_in_secs 
  FROM trip t, fare f  
  WHERE t.medallion = f.medallion AND t.hack_license = f.hack_license 
  AND t.pickup_datetime = f.pickup_datetime 
  AND t.passenger_count > 0 and t.passenger_count < 8 
  AND f.tip_amount >= 0 AND f.tip_amount <= 15 
  AND f.fare_amount >= 1 AND f.fare_amount <= 150 
  AND f.tip_amount < f.fare_amount AND t.trip_distance > 0 
  AND t.trip_distance <= 40 AND t.trip_time_in_secs >= 30 
  AND t.trip_time_in_secs <= 7200 AND t.rate_code <= 5
  AND f.payment_type in ('CSH','CRD')")
SparkR::registerTempTable(trip_fare, "trip_fare")

###########################################
# SHOW REGISTERED TABLES
###########################################
currentTables = SparkR::tables(sqlContext, databaseName = NULL)
SparkR::showDF(currentTables)
```

```
## +---------+-----------+
## |tableName|isTemporary|
## +---------+-----------+
## |     fare|       true|
## |trip_fare|       true|
## |     trip|       true|
## +---------+-----------+
```


###Feature engineering using SQL 
You can create new features using sQL statements. For example, you can use case statements to generate categorical features from coneunuous (numerical) ones.

```r
###########################################
# CREATE FEATURES IN SQL USING CASE STATEMENTS
###########################################
trip_fare_feat <- SparkR::sql(sqlContext, "
  SELECT payment_type, pickup_hour, fare_amount, tip_amount, 
    passenger_count, trip_distance, trip_time_in_secs, 
  CASE
    WHEN (pickup_hour <= 6 OR pickup_hour >= 20) THEN 'Night'
    WHEN (pickup_hour >= 7 AND pickup_hour <= 10) THEN 'AMRush' 
    WHEN (pickup_hour >= 11 AND pickup_hour <= 15) THEN 'Afternoon'
    WHEN (pickup_hour >= 16 AND pickup_hour <= 19) THEN 'PMRush'
    END as TrafficTimeBins,
  CASE
    WHEN (tip_amount > 0) THEN 1 
    WHEN (tip_amount <= 0) THEN 0 
    END as tipped
  FROM trip_fare")
```
<hr>

##Data visualization
For visualization, a small portion data will have to be sampled and brought into local memory as a data.frame object. R's plotting functions (e.g. from those in ggplot package) can then be applied to the data.frame for visualization.

```r
###########################################
# SAMPLE SMALL PORTION OF DATA
###########################################
trip_fare_featSampled <- SparkR::sample(trip_fare_feat, withReplacement=FALSE, 
                                fraction=0.0001, seed=123)

###########################################
# CONVERT SPARK DF TO LOCAL DATA.FRAME IN MEMORY OF R-SERVER EDGE NODE
###########################################
trip_fare_featSampledDF <- as.data.frame(trip_fare_featSampled);

###########################################
# PLOT HISTOGRAM OF TIP AMOUNT
###########################################
hist <- ggplot(trip_fare_featSampledDF, aes(x=tip_amount)) + 
  geom_histogram(binwidth = 0.5, aes(fill = ..count..)) + 
  scale_fill_gradient("Count", low = "green", high = "red") + 
  labs(title="Histogram for Tip Amount");

###########################################
# PLOT HISTOGRAM OF TIP AMOUNT
###########################################
scatter <- ggplot(trip_fare_featSampledDF, aes(tip_amount, trip_distance)) + 
  geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + 
  labs(title="Tip amount vs. trip distance");

grid.arrange(hist, scatter, ncol=2)
```

![](SparklyR_NYCTaxi_files/figure-html/Exploration and visualization-1.png)<!-- -->


##Down-sample data for modeling
If a data-set is large, it may need to be down-sampled for modeling in reasonable amount of time. Here we used the <b>sample</b> function from SparkR to down-sample the joined trip-fare data. We then save the data in HDFS for use as input into the sparklyr modeling functions.

```r
###########################################
# SAMPLE DATA FOR MODELING
###########################################
trip_fare_featSampled <- sample(trip_fare_feat, withReplacement=FALSE, 
                                fraction=0.1, seed=123)

###########################################
# SAVE DATAFRANE AS PARQUET file
###########################################
write.df(df=trip_fare_featSampled, 
         path='/HdiSamples/HdiSamples/NYCTaxi/JoinedSampledFile', source="parquet", mode="overwrite")
```

```
## NULL
```

<br>
<hr>
<hr>
<br>

#Using sparklyr for creating ML models
sparklyr provides bindings to Spark’s distributed machine learning library. In particular, sparklyr allows you to access the machine learning routines provided by the spark.ml package. Together with sparklyr’s dplyr interface, you can easily create and tune machine learning workflows on Spark, orchestrated entirely within R.

<br>
##Load joined trip-fare data in sparklyr spark connection and cache in memory
If a data-set is large, it may need to be down-sampled for modeling in reasonable amount of time. Here we used the <b>sample</b> function from SparkR to down-sample the joined tax-fare data. We then save the data in HDFS for use as input into the sparklyr modeling functions.

```r
###########################################
# LOAD SAMPLED JOINED TAXI DATA FROM HDFS, CACHE
###########################################
joinedDF <- spark_read_parquet(sp, name = "joined_table", 
                               path = "/HdiSamples/HdiSamples/NYCTaxi/JoinedParquetSampledFile", memory = TRUE, overwrite = TRUE)
head(joinedDF, 5)
```

```
## Source:   query [?? x 9]
## Database: spark connection master=yarn-client app=sparklyr local=FALSE
## 
##   payment_type pickup_hour fare_amount tip_amount passenger_count
##          <chr>       <int>       <dbl>      <dbl>           <int>
## 1          CRD           1        15.5        3.3               1
## 2          CSH          13         9.0        0.0               2
## 3          CRD          11         6.0        1.5               1
## 4          CRD          18        13.0        2.6               5
## 5          CRD          19        22.0        0.0               5
## # ... with 4 more variables: trip_distance <dbl>, trip_time_in_secs <int>,
## #   TrafficTimeBins <chr>, tipped <int>
```

```r
###########################################
# SHOW THE NUMBER OF OBSERVATIONS IN DATA 
###########################################
count(joinedDF)
```

```
## Source:   query [?? x 1]
## Database: spark connection master=yarn-client app=sparklyr local=FALSE
## 
##         n
##     <dbl>
## 1 1377692
```

<hr>
##Use feature transformation functions from sparklyr
Spark provides feature transformers, faciliating many common transformations of data within in a Spark DataFrame, and sparklyr exposes these within the <a href="http://spark.rstudio.com/mllib.html#transformers" target="_blank">ft_* family of functions</a>. These routines generally take one or more input columns, and generate a new output column formed as a transformation of those columns. Here, we show the use of two such functions to bucketize (categorize) or binarize features. Payment type (CSH or CRD) is binarized using string-indexer and binerizer functions. And, traffic-time bins is bucketized using the bucketizer function.

```r
###########################################
# CREATE TRANSFORMED FEATURES, BINAZURE OR BUCKET FEATURES
###########################################
# Binarizer
joinedDF2 <- joinedDF %>% ft_string_indexer(input_col = 'payment_type', output_col = 'pt_ind') %>% ft_binarizer(input_col = 'pt_ind', output_col = 'pt_bin', threshold = 0.5)

# Bucketizer
joinedDF3 <- joinedDF2 %>% ft_string_indexer(input_col = 'TrafficTimeBins', output_col = 'TrafficTimeInd') %>% ft_bucketizer(input_col = 'TrafficTimeInd', output_col = 'TrafficTimeBuc', splits=c(-1,0.5,1.5,2.5,3.5))
```

<hr>
##Create train-test partitions
Data can be partitioned into training and testing using the <b>sdf_partition</b> function. 

```r
###########################################
# CREATE TRAIN/TEST PARTITIONS
###########################################
partitions <- joinedDF3 %>% sdf_partition(training = 0.75, test = 0.25, seed = 1099)
```
<hr>

##Creating ML models
Spark’s machine learning library can be accessed from sparklyr through the <a href="http://spark.rstudio.com/mllib.html#algorithms" target="_blank">ml_* family of functions</a>. Here we create ML models for the prediction of tip-amount for taxi trips.

###Creating Elastic Net model
Create a elastic net model using training data, and evaluate on test data-set

```r
# Fit elastic net regression model
fit <- partitions$training %>% ml_linear_regression(response = "tip_amount", features = c("pt_bin", "fare_amount", "pickup_hour", "passenger_count", "trip_distance", "TrafficTimeBuc"), alpha = 0.5, lambda = 0.01)

# Show summary of fitted Elastic Net model
summary(fit)
```

```
## Call: ml_linear_regression(., response = "tip_amount", features = c("pt_bin", "fare_amount", "pickup_hour", "passenger_count", "trip_distance", "TrafficTimeBuc"), alpha = 0.5, lambda = 0.01)
## 
## Deviance Residuals: (approximate):
##       Min        1Q    Median        3Q       Max 
## -16.42945  -0.53367   0.04452   0.52461  23.40958 
## 
## Coefficients:
##     (Intercept)          pt_bin     fare_amount     pickup_hour 
##     1.168621327    -2.380945489     0.088077505     0.003203517 
## passenger_count   trip_distance  TrafficTimeBuc 
##    -0.005553378     0.060471587     0.007569128 
## 
## R-Squared: 0.6159
## Root Mean Squared Error: 1.326
```

```r
# Predict on test data & evaluate in local data-frame
predictedVals <- predict(fit, newdata =  partitions$test)
predictedVals2 <- partitions$test %>% select(tip_amount) %>% collect %>% mutate(fitted = predictedVals)
predictedDF <- as.data.frame(predictedVals2)

# Predict on test data and keep predictions in Spark context
predictedVals <- sdf_predict(fit, newdata =  partitions$test)

# Evaluate and plot predictions (R-sqr)
Rsqr = cor(predictedDF$tip_amount, predictedDF$fitted)^2; Rsqr;
```

```
## [1] 0.6202371
```

```r
# Sample predictions for plotting
predictedDFSampled <- predictedDF[base::sample(1:nrow(predictedDF), 1000),]

# Plot actual vs. predicted tip amounts
lm_model <- lm(fitted ~ tip_amount, data = predictedDFSampled)
ggplot(predictedDFSampled, aes(tip_amount, fitted)) + geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + geom_abline(aes(slope = summary(lm_model)$coefficients[2,1], intercept = summary(lm_model)$coefficients[1,1]), color = "red")
```

![](SparklyR_NYCTaxi_files/figure-html/Elastic net modeo-1.png)<!-- -->

###Creating Random Forest Model
Create a random forest model using training data, and evaluate on test data-set

```r
# Fit Random Forest regression model
fit <- partitions$training %>% ml_random_forest(response = "tip_amount", features = c("pt_bin", "fare_amount", "pickup_hour", "passenger_count",  "trip_distance", "TrafficTimeBuc"), max.bins = 500L, max.depth = 5L, num.trees = 50L)

# Show summary of fitted Random Forest model
summary(fit)
```

```
##                     Length Class      Mode       
## features             6     -none-     character  
## response             1     -none-     character  
## max.bins             1     -none-     numeric    
## max.depth            1     -none-     numeric    
## num.trees            1     -none-     numeric    
## feature.importances  6     -none-     numeric    
## trees               50     -none-     list       
## model.parameters     3     -none-     list       
## .call                7     -none-     call       
## .model               2     spark_jobj environment
```

```r
# Predict on test data & evaluate in local data-frame
predictedVals <- predict(fit, newdata =  partitions$test)
predictedVals2 <- partitions$test %>% select(tip_amount) %>% collect %>% mutate(fitted = predictedVals)
predictedDF <- as.data.frame(predictedVals2)

# Predict on test data and keep predictions in Spark context
predictedVals <- sdf_predict(fit, newdata =  partitions$test)

# Evaluate and plot predictions (R-sqr)
Rsqr = cor(predictedDF$tip_amount, predictedDF$fitted)^2; Rsqr;
```

```
## [1] 0.7508412
```

```r
# Sample predictions for plotting
predictedDFSampled <- predictedDF[base::sample(1:nrow(predictedDF), 1000),]

# Plot
lm_model <- lm(fitted ~ tip_amount, data = predictedDFSampled)
ggplot(predictedDFSampled, aes(tip_amount, fitted)) + geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + geom_abline(aes(slope = summary(lm_model)$coefficients[2,1], intercept = summary(lm_model)$coefficients[1,1]), color = "red")
```

![](SparklyR_NYCTaxi_files/figure-html/Random forest model-1.png)<!-- -->


###Creating Gradient Boosted Tree Model
Create a gradient boosted tree model using training data, and evaluate on test data-set

```r
# Fit Gradient Boosted Tree regression model
fit <- partitions$training %>% ml_gradient_boosted_trees(response = "tip_amount", features = c("pt_bin", "fare_amount","pickup_hour","passenger_count","trip_distance","TrafficTimeBuc"), max.bins = 32L, max.depth = 3L, type = "regression")

# Show summary of fitted Random Forest model
summary(fit)
```

```
##                  Length Class      Mode       
## features          6     -none-     character  
## response          1     -none-     character  
## max.bins          1     -none-     numeric    
## max.depth         1     -none-     numeric    
## trees            20     -none-     list       
## model.parameters  3     -none-     list       
## .call             7     -none-     call       
## .model            2     spark_jobj environment
```

```r
# Predict on test data & evaluate in local data-frame
predictedVals <- predict(fit, newdata =  partitions$test)
predictedVals2 <- partitions$test %>% select(tip_amount) %>% collect %>% mutate(fitted = predictedVals)
predictedDF <- as.data.frame(predictedVals2)

# Predict on test data and keep predictions in Spark context
predictedVals <- sdf_predict(fit, newdata =  partitions$test)

# Evaluate and plot predictions (R-sqr)
Rsqr = cor(predictedDF$tip_amount, predictedDF$fitted)^2; Rsqr;
```

```
## [1] 0.7839889
```

```r
# Sample predictions for plotting
predictedDFSampled <- predictedDF[base::sample(1:nrow(predictedDF), 1000),]

# Plot
lm_model <- lm(fitted ~ tip_amount, data = predictedDFSampled)
ggplot(predictedDFSampled, aes(tip_amount, fitted)) + geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + geom_abline(aes(slope = summary(lm_model)$coefficients[2,1], intercept = summary(lm_model)$coefficients[1,1]), color = "red")
```

![](SparklyR_NYCTaxi_files/figure-html/Boosted tree model-1.png)<!-- -->

<br>
<hr>
<hr>
<br>

#Summary
The examples shown here can be adopted to fit other data exploration and modeling scenarios having different data-types or prediction tasks (e.g. classification)
