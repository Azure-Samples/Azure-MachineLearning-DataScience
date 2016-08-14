# Invoke as follows:
# Rscript --default-packages= kddverification.r argumentString

args = commandArgs(trailingOnly = T)

args1 <- args[1]

argsSplit <- unlist(strsplit(args1, "-", fixed = T))
amlAuth <- argsSplit[1]
apiKey <- argsSplit[2]

# Verify files in HDFS

#rxHadoopListFiles(path="", recursive=T, print=F)

files1 <- rxHadoopListFiles("/HdiSamples/HdiSamples/FlightDelay/AirlineSubsetCsv/part-00015")

hdfsFiles <- ( files1 == 0)

#rxHadoopCommand(cmd, computeContext, sshUsername=NULL, 
                #sshHostname=NULL, 
                #sshSwitches=NULL,
                #sshProfileScript=NULL, intern=FALSE)

# Verify files on edge node
files2 <- file.exists("/home/remoteuser/Code/MRS/3-Deploy-Score-Subset.r")
edgeFiles <- files2

# Verify that we can run a Spark job
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

# Verify that we can use the AzureML package
if(Sys.getenv("R_ZIPCMD")=="")
{
  Sys.setenv(R_ZIPCMD="zip") # needed by AzureML::publishWebService
}

azureMLExists <- require(AzureML)
azureMLScore <- FALSE
if ( azureMLExists )
{
	workspace <- workspace( id = "22dff0820e214415898a098db4abcdb7", auth = amlAuth)
	services <- services(workspace)

	dataToBeScored <- as.data.frame(
        list( list( "2010", "1", "1", "1", "DL", "12173", "12758", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0" )
 	) )

	names(dataToBeScored) <- c("Year", "Month", "DayofMonth", "DayOfWeek", "Carrier", "OriginAirportID", "DestAirportID", "CRSDepTime", "CRSArrTime", "RelativeHumidityOrigin", "AltimeterOrigin", "DryBulbCelsiusOrigin", "WindSpeedOrigin", "VisibilityOrigin", "DewPointCelsiusOrigin", "RelativeHumidityDest", "AltimeterDest", "DryBulbCelsiusDest", "WindSpeedDest", "VisibilityDest", "DewPointCelsiusDest")
	
	endpoints <- endpoints(workspace, services[1,])
	scores <- NULL
	scores <- consume(endpoints, dataToBeScored)
	azureMLScore <- !is.null(scores) && is.data.frame(scores) && is.numeric(scores[1,1]) # && (scores[1,1] > 0.1385) && (scores[1,1] < 0.1386)
}

# Check that RStudio is running

command <- "ps aux | grep rstudio-server | grep -v grep"

rstudio1 <- system(command, intern = T)	
rstudioRunning <- (length(rstudio1) > 0) && grepl("/usr/lib/rstudio-server/bin/rserver", rstudio1, fixed = T)
	
# Use web service to log the results

nodeName <- Sys.info()[["nodename"]]
# nodeName <- "ed10-kdd52"
clusterID <- sub(".*-kdd", "", nodeName) # remove "ed10-kdd", leaving the node ID number
verifDF <- data.frame(clusterID, hdfsFiles, edgeFiles, sparkHPCJob, sparkHPAJob, azureMLExists, azureMLScore, rstudioRunning,
	stringsAsFactors = F)

write.csv(verifDF, "/home/remoteuser/verification.csv")

library("RCurl")
library("rjson")

# Accept SSL certificates issued by public Certificate Authorities
options(RCurlOptions = list(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")))

h = basicTextGatherer()
hdr = basicHeaderGatherer()

input1 <- list(
    "ColumnNames" = as.list(names(verifDF)),
    "Values" = list( as.list(as.integer(verifDF[1,])) )
	)

req = list(
        Inputs = list( "input1" = input1 ),
        GlobalParameters = setNames(fromJSON('{}'), character(0))
)

body = enc2utf8(toJSON(req))
api_key = apiKey
authz_hdr = paste('Bearer', api_key, sep=' ')

h$reset()
curlPerform(url = "https://ussouthcentral.services.azureml.net/workspaces/83cd1890f0174c4581e2e4aa21c2982d/services/ebf155463b204243b2248f485120dcaa/execute?api-version=2.0&details=true",
            httpheader=c('Content-Type' = "application/json", 'Authorization' = authz_hdr),
            postfields=body,
            writefunction = h$update,
            headerfunction = hdr$update,
            verbose = TRUE
            )

headers = hdr$value()
httpStatus = headers["status"]
if (httpStatus >= 400)
{
    print(paste("The request failed with status code:", httpStatus, sep=" "))

    # Print the headers - they include the request ID and the timestamp, which are useful for debugging the failure
    print(headers)
}

print("Result:")
result = h$value()
print(fromJSON(result))
