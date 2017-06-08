######################################################
#   Use R Server Operationalization to deploy the 
#   logistic regression model as a scalable web service.   
######################################################

rxSetComputeContext("local")

# Load our logistic regression model
load("logitModelSubset.RData") # loads logitModel

# Reference the test data to be scored
testDS <- RxXdfData( file.path(dataDir, "finalDataTestSubset") )

# Read the first 6 rows and remove the ArrDel15 column
dataToBeScored <- base::subset(head(testDS), select = -ArrDel15)

# Record the levels of the factor variables
colInfo <- rxCreateColInfo(dataToBeScored)

modelInfo <- list(predictiveModel = logitModel, colInfo = colInfo)

# Define a scoring function to be published as a web service
scoringFn <- function(newdata){
  library(RevoScaleR)
  data <- rxImport(newdata, colInfo = modelInfo$colInfo)
  rxPredict(modelInfo$predictiveModel, data)
}

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
name <- "Delay_Prediction_Service" # name must not contain spaces
version <- "v1.0.0"

# deleteService(name, version)

# publish the scoring function web service
api_frame <- publishService(
  name = name,
  code = scoringFn,
  model = modelInfo,
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


################################################
# You can call and integrate the web services into 
# other applications using the service-specific 
# Swagger-based JSON file along with the required inputs. 
################################################
swagger <- api_frame$swagger()
cat(swagger, file = "swagger.json", append = FALSE)


