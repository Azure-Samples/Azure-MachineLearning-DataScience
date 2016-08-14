###########################################
# CREATE SPARK CONTEXT
###########################################
list.files(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"))
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
library(SparkR)

sparkEnvir <- list(spark.executor.instance = '10', spark.yarn.executor.memoryOverhead = '8000')
sc <- sparkR.init(
  sparkEnvir = sparkEnvir,
  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0"
)
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

###########################################
# LOAD SAMPLED JOINED TAXI DATA FROM HDFS, CACHE
###########################################
joinedDF <- spark_read_parquet(sp, name = "joined_table", 
                               path = "/HdiSamples/HdiSamples/NYCTaxi/JoinedParquetSampledFile", memory = TRUE, overwrite = TRUE)
head(joinedDF, 5)

###########################################
# SHOW THE NUMBER OF OBSERVATIONS IN DATA 
###########################################
count(joinedDF)

###########################################
# SAMPLE SMALL PORTION (1000 rows) OF DATA 
###########################################
joinedSampled <- dplyr::sample_n(joinedDF, 1000)

###########################################
# CONVERT SPARK DF TO LOCAL DATA.FRAME IN MEMORY OF R-SERVER EDGE NODE
###########################################
joinedSampledDF <- as.data.frame(joinedSampled);

###########################################
# Generate HISTOGRAM OF TIP AMOUNT
###########################################
hist <- ggplot(joinedSampledDF, aes(x=tip_amount)) + 
  geom_histogram(binwidth = 0.5, aes(fill = ..count..)) + 
  scale_fill_gradient("Count", low = "green", high = "red") + 
  labs(title="Histogram for Tip Amount");

###########################################
# Generate Scatter Plot of TIP AMOUNT vs. TRIP DISTANCE
###########################################
scatter <- ggplot(joinedSampledDF, aes(tip_amount, trip_distance)) + 
  geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + 
  labs(title="Tip amount vs. trip distance");

###########################################
# Plot the Histogramand Scatter Plot Side by Side
###########################################
grid.arrange(hist, scatter, ncol=2)

###########################################
# CREATE TRANSFORMED FEATURES, BINAZURE OR BUCKET FEATURES
###########################################
# Binarizer
joinedDF2 <- joinedDF %>% ft_string_indexer(input_col = 'payment_type', output_col = 'pt_ind') %>% ft_binarizer(input_col = 'pt_ind', output_col = 'pt_bin', threshold = 0.5)

head(joinedDF2, 5)
# Bucketizer
joinedDF3 <- joinedDF2 %>% ft_string_indexer(input_col = 'TrafficTimeBins', output_col = 'TrafficTimeInd') %>% ft_bucketizer(input_col = 'TrafficTimeInd', output_col = 'TrafficTimeBuc', splits=c(-1,0.5,1.5,2.5,3.5))

head(joinedDF3, 5)

###########################################
# CREATE TRAIN/TEST PARTITIONS
###########################################
partitions <- joinedDF3 %>% sdf_partition(training = 0.75, test = 0.25, seed = 1099)

###########################################
# BUILD MACHINE LEARNING ELASTIC NET REGRESSION MODELS AND EVALUATE
###########################################

fit <- partitions$training %>% ml_linear_regression(response = "tip_amount", features = c("pt_bin", "fare_amount", "pickup_hour", "passenger_count", "trip_distance", "TrafficTimeBuc"), alpha = 0.5, lambda = 0.01)

# Show summary of fitted Elastic Net model
summary(fit)

# Predict on test data & evaluate in local data-frame
predictedVals <- predict(fit, newdata =  partitions$test)
predictedVals2 <- partitions$test %>% select(tip_amount) %>% collect %>% mutate(fitted = predictedVals)
predictedDF <- as.data.frame(predictedVals2)

# Predict on test data and keep predictions in Spark context
predictedVals <- sdf_predict(fit, newdata =  partitions$test)

# Evaluate and plot predictions (R-sqr)
Rsqr = cor(predictedDF$tip_amount, predictedDF$fitted)^2; Rsqr;

# Sample predictions for plotting
predictedDFSampled <- predictedDF[base::sample(1:nrow(predictedDF), 1000),]

# Plot actual vs. predicted tip amounts
lm_model <- lm(fitted ~ tip_amount, data = predictedDFSampled)
ggplot(predictedDFSampled, aes(tip_amount, fitted)) + geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + geom_abline(aes(slope = summary(lm_model)$coefficients[2,1], intercept = summary(lm_model)$coefficients[1,1]), color = "red")

###########################################
# BUILD MACHINE LEARNING RANDOM FOREST REGRESSION MODELS AND EVALUATE
###########################################
fit <- partitions$training %>% ml_random_forest(response = "tip_amount", features = c("pt_bin", "fare_amount", "pickup_hour", "passenger_count",  "trip_distance", "TrafficTimeBuc"), max.bins = 500L, max.depth = 5L, num.trees = 50L)

# Show summary of fitted Random Forest model
summary(fit)

# Predict on test data & evaluate in local data-frame
predictedVals <- predict(fit, newdata =  partitions$test)
predictedVals2 <- partitions$test %>% select(tip_amount) %>% collect %>% mutate(fitted = predictedVals)
predictedDF <- as.data.frame(predictedVals2)

# Predict on test data and keep predictions in Spark context
predictedVals <- sdf_predict(fit, newdata =  partitions$test)

# Evaluate and plot predictions (R-sqr)
Rsqr = cor(predictedDF$tip_amount, predictedDF$fitted)^2; Rsqr;

# Sample predictions for plotting
predictedDFSampled <- predictedDF[base::sample(1:nrow(predictedDF), 1000),]

# Plot
lm_model <- lm(fitted ~ tip_amount, data = predictedDFSampled)
ggplot(predictedDFSampled, aes(tip_amount, fitted)) + geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + geom_abline(aes(slope = summary(lm_model)$coefficients[2,1], intercept = summary(lm_model)$coefficients[1,1]), color = "red")

###########################################
# BUILD MACHINE LEARNING GBM REGRESSION MODELS AND EVALUATE
###########################################
fit <- partitions$training %>% ml_gradient_boosted_trees(response = "tip_amount", features = c("pt_bin", "fare_amount","pickup_hour","passenger_count","trip_distance","TrafficTimeBuc"), max.bins = 32L, max.depth = 3L, type = "regression")

# Show summary of fitted Random Forest model
summary(fit)

# Predict on test data & evaluate in local data-frame
predictedVals <- predict(fit, newdata =  partitions$test)
predictedVals2 <- partitions$test %>% select(tip_amount) %>% collect %>% mutate(fitted = predictedVals)
predictedDF <- as.data.frame(predictedVals2)

# Predict on test data and keep predictions in Spark context
predictedVals <- sdf_predict(fit, newdata =  partitions$test)

# Evaluate and plot predictions (R-sqr)
Rsqr = cor(predictedDF$tip_amount, predictedDF$fitted)^2; Rsqr;

# Sample predictions for plotting
predictedDFSampled <- predictedDF[base::sample(1:nrow(predictedDF), 1000),]

# Plot
lm_model <- lm(fitted ~ tip_amount, data = predictedDFSampled)
ggplot(predictedDFSampled, aes(tip_amount, fitted)) + geom_point(col='darkgreen', alpha=0.3, pch=19, cex=2) + geom_abline(aes(slope = summary(lm_model)$coefficients[2,1], intercept = summary(lm_model)$coefficients[1,1]), color = "red")