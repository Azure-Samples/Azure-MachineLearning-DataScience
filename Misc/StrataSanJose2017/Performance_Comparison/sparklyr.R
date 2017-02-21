# install "sparklyr" package:
# install.packages("sparklyr")


##############################################################

#### execute .R scripts in command line for multiple experiments.
# Rscript sparklyr.R "airline_1MM.csv" "~/results/sparklyr/sparklyr_1MM.csv"
# Rscript sparklyr.R "airline_2MM.csv" "~/results/sparklyr/sparklyr_2MM.csv"
# Rscript sparklyr.R "airline_5MM.csv" "~/results/sparklyr/sparklyr_5MM.csv"
# Rscript sparklyr.R "airline_10MM.csv" "~/results/sparklyr/sparklyr_10MM.csv"
# Rscript sparklyr.R "airline_20MM.csv" "~/results/sparklyr/sparklyr_20MM.csv"
# Rscript sparklyr.R "airline_50MM.csv" "~/results/sparklyr/sparklyr_50MM.csv"
# Rscript sparklyr.R "airline_100MM.csv" "~/results/sparklyr/sparklyr_100MM.csv"
# Rscript sparklyr.R "airline_200MM.csv" "~/results/sparklyr/sparklyr_200MM.csv"
# Rscript sparklyr.R "airline_400MM.csv" "~/results/sparklyr/sparklyr_400MM.csv"
# Rscript sparklyr.R "airline_800MM.csv" "~/results/sparklyr/sparklyr_800MM.csv"
# Rscript sparklyr.R "airline_1000MM.csv" "~/results/sparklyr/sparklyr_1000MM.csv"



#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Inputs:
# fileName <- "airline_1MM.csv"
fileName <- args[1]


# call libraries
library("sparklyr")
library("dplyr")


# part 1: reading data
pt1 <- proc.time()

# connect to remote Spark clusters
config <- spark_config()
config$spark.dynamicAllocation.enabled <- "true"
config$spark.shuffle.service.enabled <- "true"
config$spark.dynamicAllocation.minExecutors <- 1

sc <- spark_connect(master = "yarn-client", config = config)

# import data
inputPath <- file.path("wasb://<container_name>@<blob_name>.blob.core.windows.net", fileName)
airline_lyr <- spark_read_csv(sc,
                              name = gsub(".csv", "", fileName),
                              path = inputPath,
                              header = TRUE)
pt2 <- proc.time()
print("FINISHED LOADING DATA...")



# part 2: data transformation on CRSDepTime
airline_lyr <- airline_lyr %>% mutate(CRSDepTime = floor(CRSDepTime / 100))
pt3 <- proc.time()
print("FINISHED DATA TRANSFORMATION...")



# part 3: split train/test
partitions <- airline_lyr %>% sdf_partition(train = 0.75, test = 0.25, seed = 123)
pt4 <- proc.time()
print("FINISHED SPLITTING DATA...")



# part 4: fit model
# ml_logistic_regression
ml_model <- partitions$train %>% ml_logistic_regression(response = "IsArrDelayed", 
                                                        features = c("Month", "DayofMonth", "DayOfWeek", "CRSDepTime", "Distance"),
                                                        iter.max = 25)
pt5 <- proc.time()
print("FINISHED FITTING MODEL...")



# part 5: predict on test
p <- sdf_predict(ml_model, partitions$test) # %>% select(prediction)
outFile <- file.path("wasb://<container_name>@<blob_name>.blob.core.windows.net", "sparklyr", paste0(gsub(".csv", "", fileName), "_pred"))
spark_write_parquet(p, outFile, mode = "overwrite")
pt6 <- proc.time()
print("FINISHED PREDICTION...")

# disconnect
spark_disconnect(sc)



# part 6: output results
results <- data.frame("number of rows" = fileName,
                      "load data" = (pt2-pt1)[[3]],
                      "tranform feature" = (pt3-pt2)[[3]],
                      "split data" = (pt4-pt3)[[3]],
                      "fit model" = (pt5-pt4)[[3]],
                      "prediction" = (pt6-pt5)[[3]],
                      "total" = (pt6-pt1)[[3]])


# "~/results/sparklyr/sparklyr_1MM.csv"
write.csv(results, args[2], row.names = FALSE)
print("FINISHED WRITTING OUTPUTS...")