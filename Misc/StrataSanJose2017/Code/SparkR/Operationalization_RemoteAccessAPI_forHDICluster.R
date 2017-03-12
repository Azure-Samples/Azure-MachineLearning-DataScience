###############################################################
## Remote Login 
###############################################################
remoteLogin(
  "http://localhost:12800",
  username = "admin",
  password = "",
  session = FALSE
)
listServices()

###############################################################
## Call API
###############################################################
version <- "v0.0.1"
api_1 <- getService("scoring_input_files", version)

modelfile <- "/HdiSamples/HdiSamples/NYCTaxi/SparkGlmModel"
input <- "/HdiSamples/HdiSamples/NYCTaxi/NYCjoinedParquetSubsetSampled"
output <- "/HdiSamples/HdiSamples/NYCTaxi/SparkRGLMPredictionsClient"

result_1 <- api_1$web_scoring(
  modelfile = modelfile,
  input = input,
  output = output
)


result_1$success
