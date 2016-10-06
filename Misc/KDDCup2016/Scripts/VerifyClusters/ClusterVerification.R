# Invoke as follows:
# Rscript --default-packages=  ClusterVerification.R

############################################################################################
# Verify files in HDFS
############################################################################################

files1 <- rxHadoopListFiles("/HdiSamples/HdiSamples/FlightDelay/AirlineSubsetCsv/", print = F)
files2 <- rxHadoopListFiles("/HdiSamples/HdiSamples/FlightDelay/WeatherSubsetCsv/", print = F)
files3 <- rxHadoopListFiles("/HdiSamples/HdiSamples/NYCTaxi/Csv/", print = F)
files4 <- rxHadoopListFiles("/HdiSamples/HdiSamples/NYCTaxi/JoinedParquetSampledFile/", print = F)

hdfsFiles <- (length(files1) == 17) && (length(files2) == 17) && (length(files3) == 3) && (length(files4) == 201)

############################################################################################
# Verify some of the files on the edge node
############################################################################################

edgeMRSFiles <- (file.exists("/home/remoteuser/Code/MRS/1-Clean-Join-Subset.r") && file.exists("/home/remoteuser/Code/MRS/2-Train-Test-Subset.r") && file.exists("/home/remoteuser/Code/MRS/3-Deploy-Score-Subset.r") &&
                file.exists("/home/remoteuser/Code/MRS/SetComputeContext.r") && file.exists("/home/remoteuser/Code/MRS/Installation.r") && file.exists("/home/remoteuser/Code/MRS/azureml-settings.json") )

edgeSparklyRFiles <- (file.exists("/home/remoteuser/Code/SparkR/sparklyr_NYCTaxi.Rmd") && file.exists("/home/remoteuser/Code/SparkR/SparkR_sparklyr_NYCTaxi.Rmd"))

############################################################################################
# Verify that we can run Spark jobs
############################################################################################

rxOptions(fileSystem = RxHdfsFileSystem())

# Specify hdfsShareDir and shareDir so that
# RxSpark will work even if we run as root
computeContext <- RxSpark(consoleOutput=TRUE,
	hdfsShareDir = "/user/RevoShare/remoteuser",
	shareDir = "/var/RevoShare/remoteuser")
rxSetComputeContext(computeContext)

spark1 <- NULL
spark1 <- rxExec(file.exists, "/usr/bin/R")
sparkHPCJob <- ( !is.null(spark1) && !is.null(spark1$rxElem1) && spark1$rxElem1 )

txtDS <- RxTextData("/HdiSamples/HdiSamples/FlightDelay/AirlineSubsetCsv/part-00015")
spark2 <- NULL
spark2 <- rxSummary(~., txtDS)
sparkHPAJob <- ( !is.null(spark2) && !is.null(spark2$nobs.valid) && (spark2$nobs.valid == 118806 ) )

############################################################################################
# Verify that we can use the AzureML package
############################################################################################

if (Sys.getenv("R_ZIPCMD") == "")
{
  Sys.setenv(R_ZIPCMD="zip") # needed by AzureML::publishWebService
}

azureMLExists <- require(AzureML)

############################################################################################
# Check that RStudio is running
############################################################################################

command <- "ps aux | grep rstudio-server | grep -v grep"

rstudio1 <- system(command, intern = T)	
rstudioRunning <- (length(rstudio1) > 0) && grepl("/usr/lib/rstudio-server/bin/", rstudio1, fixed = T)
	
############################################################################################
# Log the results
############################################################################################

verifDF <- data.frame(hdfsFiles, edgeMRSFiles, edgeSparklyRFiles, sparkHPCJob, sparkHPAJob, azureMLExists, rstudioRunning, stringsAsFactors = F)

write.csv(verifDF, "/home/remoteuser/verification.csv", row.names = FALSE)
