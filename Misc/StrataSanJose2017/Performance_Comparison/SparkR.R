#### execute .R scripts in command line for multiple experiments.
# Rscript SparkR.R "airline_1MM.csv" "~/results/sparkR/sparkR_1MM.csv"
# Rscript SparkR.R "airline_2MM.csv" "~/results/sparkR/sparkR_2MM.csv"
# Rscript SparkR.R "airline_5MM.csv" "~/results/sparkR/sparkR_5MM.csv"
# Rscript SparkR.R "airline_10MM.csv" "~/results/sparkR/sparkR_10MM.csv"
# Rscript SparkR.R "airline_20MM.csv" "~/results/sparkR/sparkR_20MM.csv"
# Rscript SparkR.R "airline_50MM.csv" "~/results/sparkR/sparkR_50MM.csv"
# Rscript SparkR.R "airline_100MM.csv" "~/results/sparkR/sparkR_100MM.csv"
# Rscript SparkR.R "airline_200MM.csv" "~/results/sparkR/sparkR_200MM.csv"
# Rscript SparkR.R "airline_400MM.csv" "~/results/sparkR/sparkR_400MM.csv"
# Rscript SparkR.R "airline_800MM.csv" "~/results/sparkR/sparkR_800MM.csv"
# Rscript SparkR.R "airline_1000MM.csv" "~/results/sparkR/sparkR_1000MM.csv"



#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
options(warn=-1)

# Inputs:
# fileName <- "airline_1MM.csv"
fileName <- args[1]


# call libraries
.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R", "lib"), .libPaths()))
library("SparkR")
library("dplyr")


# part 1: reading data
pt1 <- proc.time()
# connect R to a Spark cluster
sc <- sparkR.init(master = "yarn-client",
                  sparkPackages = "com.databricks:spark-csv_2.10:1.3.0",
                  sparkEnvir = list(spark.dynamicAllocation.enabled = "true",
                                    spark.shuffle.service.enabled = "true",
                                    spark.dynamicAllocation.minExecutors = "1"))
sqlContext <- sparkRSQL.init(sc)


# import data
inputPath <- file.path("wasb://<container_name>@<blob_name>.blob.core.windows.net", fileName)
# define data schema
airline_sparkr <- read.df(sqlContext, path = inputPath, 
                          header = "true", source = "com.databricks.spark.csv",
                          inferSchema = "true")
pt2 <- proc.time()
print("FINISH LOADING DATA...")



# part 2: data transformation on CRSDepTime
airline_sparkr$CRSDepTime <- floor(airline_sparkr$CRSDepTime / 100)
pt3 <- proc.time()
print("FINISHED DATA TRANSFORMATION...")



# part 3: split train/test
train <- SparkR::sample_frac(airline_sparkr, withReplacement=FALSE, fraction=0.75, seed=123)
test <- SparkR::except(airline_sparkr, train)
pt4 <- proc.time()
print("FINISHED SPLITTING DATA...")



# part 4: fit model
# GLM model
model_sparkr <- glm(formula = IsArrDelayed ~ Month+DayofMonth+DayOfWeek+CRSDepTime+Distance, 
                    data = train, family = "binomial")
pt5 <- proc.time()
print("FINISHED FITTING MODEL...")



# part 5: predict on test
p <- SparkR::select(SparkR::predict(model_sparkr, test), "prediction")
outFile <- file.path("wasb://<container_name>@<blob_name>.blob.core.windows.net", "sparkR", paste0(gsub(".csv", "", fileName), "_pred"))
# prepare for overwrite
if (rxHadoopFileExists(outFile) == TRUE) {
  rxHadoopRemoveDir(outFile)
}
write.parquet(p, outFile)
pt6 <- proc.time()
print("FINISHED PREDICTION...")

# stop Spark connection
sparkR.session.stop()



# part 6: output results
results <- data.frame("number of rows" = fileName,
                      "load data" = (pt2-pt1)[[3]],
                      "tranform feature" = (pt3-pt2)[[3]],
                      "split data" = (pt4-pt3)[[3]],
                      "fit model" = (pt5-pt4)[[3]],
                      "prediction" = (pt6-pt5)[[3]],
                      "total" = (pt6-pt1)[[3]])


# "~/results/sparkR/sparkR_1MM.csv"
write.csv(results, args[2], row.names = FALSE)
print("FINISHED WRITTING OUTPUTS...")
