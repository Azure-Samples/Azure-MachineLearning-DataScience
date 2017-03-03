######################################################################
## Remote Login using mrsdeploy
######################################################################
library(mrsdeploy)
remoteLogin(
  #"http://127.0.0.1:12800",
  "http://<vm-name>.westus.cloudapp.azure.com:12800",
  username = "****",
  password = "******",
  session = FALSE
)
listServices()


######################################################################
## Call API
######################################################################
version <- "v0.0.1"
api_1 <- getService("scoring_input_files", version)

modelfile <- "/user/RevoShare/remoteuser/Models/SparkGlmModel"
input <- "/user/RevoShare/remoteuser/Data/NYCjoinedParquetSubset"
output <- "/user/RevoShare/rserve2/Predictions/SparkRGLMPred"

result_1 <- api_1$web_scoring(
  modelfile = modelfile,
  input = input,
  output = output
)

