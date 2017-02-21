#### execute .R scripts in command line for multiple experiments.
# Rscript --default-packages=methods,utils mrs.R "airline_1MM.csv" "~/results/mrs/mrs_1MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_2MM.csv" "~/results/mrs/mrs_2MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_5MM.csv" "~/results/mrs/mrs_5MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_10MM.csv" "~/results/mrs/mrs_10MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_20MM.csv" "~/results/mrs/mrs_20MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_50MM.csv" "~/results/mrs/mrs_50MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_100MM.csv" "~/results/mrs/mrs_100MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_200MM.csv" "~/results/mrs/mrs_200MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_400MM.csv" "~/results/mrs/mrs_400MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_800MM.csv" "~/results/mrs/mrs_800MM.csv"
# Rscript --default-packages=methods,utils mrs.R "airline_1000MM.csv" "~/results/mrs/mrs_1000MM.csv"



#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

# Inputs:
# fileName <- "airline_1MM.csv"
fileName <- args[1]

# create a temporary directory in blob
# this code only needs to be executed once 
rxHadoopMakeDir(file.path(myNameNode, bigDataDirRoot, "temp"))


# call libraries
library("RevoScaleR")



# part 1: reading data
pt1 <- proc.time()
myNameNode <- "wasb://<container_name>@<blob_name>.blob.core.windows.net"
myPort <- 0
bigDataDirRoot <- ""

# Define HDFS file system.
hdfsFS <- RxHdfsFileSystem(hostName = myNameNode, port = myPort)

# Define Spark compute context.
mySparkCluster <- rxSparkConnect(hdfsShareDir = bigDataDirRoot,
                                 nameNode = myNameNode,
                                 port = myPort,
                                 extraSparkConfig = "--conf spark.dynamicAllocation.enabled=true --conf spark.shuffle.service.enabled=true --conf spark.dynamicAllocation.minExecutors=1",
                                 idleTimeout = 86400000,
                                 consoleOutput = TRUE,
                                 fileSystem = hdfsFS)

# Specify the input file in HDFS to analyze.
inputFile <- file.path(bigDataDirRoot, fileName)
outFileName <- "temp/airlineXDF"
outFile <- file.path(bigDataDirRoot, outFileName)

# Define the data source.
inputDS <- RxTextData(file = inputFile,
                      missingValueString = "M",
                      firstRowIsColNames = TRUE,
                      delimiter = ",",
                      fileSystem = hdfsFS)

# Define out file
outFileXDF <- RxXdfData(file = outFile,
                        fileSystem = hdfsFS)



# import data into XDF
# part 2: data transformation on CRSDepTime
set.seed(123)
rxImport(inData = inputDS, outFile = outFileXDF, 
         transforms = list(CRSDepTime = floor(CRSDepTime / 100),
                           testSplitVar = ( runif( .rxNumRows ) > 0.25 )),
         fileSystem = hdfsFS,
         overwrite = TRUE)
pt2 <- proc.time()
pt3 <- proc.time()
print("FINISHED LOADING DATA...")
print("FINISHED DATA TRANSFORMATION...")



# part 3: split train/test
testXdfFile <- file.path(bigDataDirRoot, "temp/testXDF")
testDS <- RxXdfData(file = testXdfFile, fileSystem = hdfsFS)
rxDataStep( inData = outFileXDF, outFile = testDS,
            rowSelection = ( testSplitVar == 0),
            overwrite = TRUE)
pt4 <- proc.time()
print("FINISHED SPLITTING DATA...")



# part 4: fit model
# rxLogit
model_mrs <- rxLogit(formula = IsArrDelayed ~ Month+DayofMonth+DayOfWeek+CRSDepTime+Distance, data = outFileXDF,
                     rowSelection = ( testSplitVar == 1))
pt5 <- proc.time()
print("FINISHED FITTING MODEL...")



# part 5: predict on test
predictXdfFile <- file.path(bigDataDirRoot, "temp/predictXDF")
predictDS <- RxXdfData(file = predictXdfFile, fileSystem = hdfsFS)
rxPredict(modelObject = model_mrs, data = testDS, outData = predictDS,
          type = "response", predVarNames = "predictArrDelayed", overwrite = TRUE)
pt6 <- proc.time()
print("FINISHED PREDICTION...")

# stop Spark connection
rxSparkDisconnect(mySparkCluster)



# part 6: output results
results <- data.frame("number of rows" = fileName,
                      "load data" = (pt2-pt1)[[3]],
                      "tranform feature" = (pt3-pt2)[[3]],
                      "split data" = (pt4-pt3)[[3]],
                      "fit model" = (pt5-pt4)[[3]],
                      "prediction" = (pt6-pt5)[[3]],
                      "total" = (pt6-pt1)[[3]])


# "~/results/mrs/mrs_1MM.csv"
write.csv(results, args[2], row.names = FALSE)
print("FINISHED WRITTING OUTPUTS...")

