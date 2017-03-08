# Use R Server Operationalization to deploy the tree-based model as a scalable web service.
setwd("/home/remoteuser/Code/MRS")
source("SetComputeContext.r")

# Load our rxDTree Decision Tree model

load("dTreeModelSubset.RData") # loads dTreeModel

# Define a scoring function to be published as a web service

scoringFn <- function(newdata){
  library(RevoScaleR)
  rxPredict(dTreeModel, newdata)
}

trainDS <- RxXdfData( file.path(dataDir, "finalDataTrainSubset") )

rxSetComputeContext("local")
exampleDF <- base::subset(head(trainDS), select = -ArrDel15)

testDS <- RxXdfData( file.path(dataDir, "finalDataTestSubset") )

dataToBeScored <- base::subset(head(testDS), select = -ArrDel15)

# Test the scoring function locally

scoringFn(exampleDF)


######################################################
#   Authenticate with the Operationalization service    
######################################################
# load mrsdeploy package

library(mrsdeploy)

myUsername <- "admin"
myPassword <- "INSERT PASSWORD HERE"

remoteLogin(
  "http://127.0.0.1:12800",
  username = myUsername,
  password = myPassword,
  session = FALSE
)

################################################
# Deploy the scoring function as a web service
################################################

# specify the version
version <- "v1.1"

# publish the scoring function web service
api_frame <- publishService(
  name = "Delay_Prediction_Service", # name must not contain spaces
  code = scoringFn,
  model = "dTreeModelSubset.RData",
  inputs = list(newdata = "data.frame"),
  outputs = list(answer = "data.frame"),
  v = version
)

# N.B. To update an existing web service, either
# 1) use the updateService function, or 
# 2) change the version number

################################################
# Score new data via the web service
################################################

endpoint <- getService("Delay_Prediction_Service", version)

response <- endpoint$scoringFn(dataToBeScored)

scores <- response$output("answer")

head(scores)
