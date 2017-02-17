## Remote Login 
remoteLogin(
  "http://localhost:12800",
  username = "***",
  password = "*********",
  session = FALSE
)
listServices()


version <- "v1.1.21"
api_1 <- getService("scoring_string_input", version)

modelfile <- "/user/RevoShare/remoteuser/Models/SparkRGLM"
input <- "/user/RevoShare/remoteuser/Data/NYCjoinedParquetSubset"
output <- "/user/RevoShare/rserve2/Predictions/SparkRGLMPredRemote"

result_1 <- api_1$web_scoring(
  modelfile = modelfile,
  input = input,
  output = output
)