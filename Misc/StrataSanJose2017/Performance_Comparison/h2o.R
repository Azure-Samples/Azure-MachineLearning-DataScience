# # The following two commands remove any previously installed H2O packages for R.
# if ("package:h2o" %in% search()) { detach("package:h2o", unload=TRUE) }
# if ("h2o" %in% rownames(installed.packages())) { remove.packages("h2o") }
# 
# # Next, we download packages that H2O depends on.
# pkgs <- c("methods","statmod","stats","graphics","RCurl","jsonlite","tools","utils")
# for (pkg in pkgs) {
#   if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg, repos = "http://cran.rstudio.com/") }
# }
# 
# # Now we download, install and initialize the H2O package for R.
# install.packages("h2o", type="source", repos=(c("http://h2o-release.s3.amazonaws.com/h2o/rel-turing/10/R")))
# install.packages("sparklyr")
# install.packages("devtools")
# library(devtools)
# devtools::install_github("h2oai/rsparkling", ref = "master") 



##############################################################

#### execute .R scripts in command line for multiple experiments.
# Rscript h2o.R "airline_1MM.csv" "~/results/h2o/h2o_1MM.csv"
# Rscript h2o.R "airline_2MM.csv" "~/results/h2o/h2o_2MM.csv"
# Rscript h2o.R "airline_5MM.csv" "~/results/h2o/h2o_5MM.csv"
# Rscript h2o.R "airline_10MM.csv" "~/results/h2o/h2o_10MM.csv"
# Rscript h2o.R "airline_20MM.csv" "~/results/h2o/h2o_20MM.csv"
# Rscript h2o.R "airline_50MM.csv" "~/results/h2o/h2o_50MM.csv"
# Rscript h2o.R "airline_100MM.csv" "~/results/h2o/h2o_100MM.csv"
# Rscript h2o.R "airline_200MM.csv" "~/results/h2o/h2o_200MM.csv"
# Rscript h2o.R "airline_400MM.csv" "~/results/h2o/h2o_400MM.csv"
# Rscript h2o.R "airline_800MM.csv" "~/results/h2o/h2o_800MM.csv"
# Rscript h2o.R "airline_1000MM.csv" "~/results/h2o/h2o_1000MM.csv"



#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Inputs:
# fileName <- "airline_1MM.csv"
fileName <- args[1]


# call libraries
library("sparklyr")
library("h2o")
options(rsparkling.sparklingwater.version = "2.0.3") # Using Sparkling Water 2.0.3
library("rsparkling") 


# part 1: reading data
pt1 <- proc.time()

# connect to remote Spark clusters
config <- spark_config()
# spark config
config$spark.num.executors <- 11
config$spark.executor.cores <- 5
config$spark.executor.memory <- "34G"
config$spark.driver.memory <- "34G"
# sparkling water config
config$spark.ext.h2o.disable.ga <- "true"
config$spark.ext.h2o.client.log.dir <- "h2ologs"
config$spark.ext.h2o.client.verbose <- "true"
# internal h2o backend config
config$spark.ext.h2o.cloud.timeout <- 86400000
config$spark.ext.h2o.node.log.dir <- "h2ologs"

sc <- spark_connect(master = "yarn-client", config = config, version = "2.0.2")

# create h2o context
h2o_context(sc, strict_version_check = FALSE)

# import data
inputPath <- file.path("wasb://<container_name>@<blob_name>.blob.core.windows.net", fileName)
airline_lyr <- spark_read_csv(sc,
                              name = gsub(".csv", "", fileName),
                              path = inputPath,
                              header = TRUE)

# convert SparkDataFrame to h2oFrame
airline_h2o <- as_h2o_frame(sc, airline_lyr, strict_version_check = FALSE)
pt2 <- proc.time()
print("FINISH LOADING DATA...")



# part 2: data transformation on CRSDepTime
airline_h2o$CRSDepTime <- floor(airline_h2o$CRSDepTime / 100)
pt3 <- proc.time()
print("FINISHED DATA TRANSFORMATION...")



# part 3: split train/test
partitions <- h2o.splitFrame(airline_h2o, ratios = 0.75, seed = 123)
train <- partitions[[1]]
test <- partitions[[2]]
pt4 <- proc.time()
print("FINISHED SPLITTING DATA...")



# part 4: fit model
# h2o.glm with no regularization
model_h2o <- h2o.glm(y = "IsArrDelayed",
                     x = c("Month", "DayofMonth", "DayOfWeek", "CRSDepTime", "Distance"),
                     training_frame = train, seed = 123,
                     family = "binomial", lambda = 0, max_iterations = 25)
pt5 <- proc.time()
print("FINISHED FITTING MODEL...")



# part 5: predict on test
p <- h2o.predict(model_h2o, newdata = test)
p_sdf <- as_spark_dataframe(sc, p, strict_version_check = FALSE)
outFile <- file.path("wasb://<container_name>@<blob_name>.blob.core.windows.net", "h2o", paste0(gsub(".csv", "", fileName), "_pred"))
spark_write_parquet(p_sdf, outFile, mode = "overwrite")
pt6 <- proc.time()
print("FINISHED PREDICTION...")

# disconnect
h2o.shutdown(prompt = FALSE)
spark_disconnect(sc)



# part 7: output results
results <- data.frame("number of rows" = fileName,
                      "load data" = (pt2-pt1)[[3]],
                      "tranform feature" = (pt3-pt2)[[3]],
                      "split data" = (pt4-pt3)[[3]],
                      "fit model" = (pt5-pt4)[[3]],
                      "prediction" = (pt6-pt5)[[3]],
                      "total" = (pt6-pt1)[[3]]
)



# "~/results/h2o/h2o_1MM.csv"
utils::write.csv(results, args[2], row.names = FALSE)
print("FINISHED WRITTING OUTPUTS...")

