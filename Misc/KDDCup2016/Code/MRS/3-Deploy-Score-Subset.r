# Use the AzureML CRAN package to deploy the tree-based model as a scalable web service.
setwd("/home/remoteuser/Code/MRS")
source("SetComputeContext.r")

# Load our rxDTree Decision Tree model

load("dTreeModelSubset.RData") # loads dTreeModel

# Convert to open source R model

rpartModel <- as.rpart( dTreeModel )

# Define a scoring function to be published as a web service

scoringFn <- function(newdata){
  library(rpart)
  predict(rpartModel, newdata=newdata)
}

trainDS <- RxXdfData( file.path(dataDir, "finalDataTrainSubset") )

exampleDF <- base::subset(head(trainDS), select = -ArrDel15)

testDS <- RxXdfData( file.path(dataDir, "finalDataTestSubset") )

dataToBeScored <- base::subset(head(testDS), select = -ArrDel15)

# Test the scoring function locally

scoringFn(exampleDF)

################################################
# Publish the scoring function as a web service
################################################

library(AzureML)

workspace <- workspace(config = "azureml-settings.json")

endpoint <- publishWebService(workspace, scoringFn,
                              name="Delay Prediction Service",
                              inputSchema = exampleDF)

################################################
# Score new data via the web service
################################################

scores <- consume(endpoint, dataToBeScored)

head(scores)
