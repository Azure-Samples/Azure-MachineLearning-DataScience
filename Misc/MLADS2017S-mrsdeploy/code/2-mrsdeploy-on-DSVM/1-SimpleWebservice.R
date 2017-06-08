##########################################################
#       Create & Test a Model                            #
##########################################################

library(mrsdeploy)

addFunction <- function(x, y) {
  x + y
}

# test function locally by printing results
print(addFunction(120, 2.8))


##########################################################
#            Log into Microsoft R Server                 #
##########################################################

# Use `remoteLogin` to authenticate with R Server using 
# the local admin account. Use session = false so no 
# remote R session started
remoteLogin("http://localhost:12800", 
            username = "admin", 
            password = "<YOUR_PASSWORD>",
            session = FALSE)



##########################################################
#             Publish Model as a Service                 #
##########################################################

# Generate a unique serviceName for demos 
# and assign to variable serviceName
serviceName <- paste0("addService", round(as.numeric(Sys.time()), 0))

# Publish as service using `publishService()` function from 
# `mrsdeploy` package. 
api <- publishService(
  name = serviceName,
  code = addFunction,
  inputs = list(x = "numeric", y = "numeric"),
  outputs = list(result = "numeric")
)


##########################################################
#                 Consume Service in R                   #
##########################################################

# Print capabilities that define the service holdings: service 
# name, version, descriptions, inputs, outputs, and the 
# name of the function to be consumed
print(api$capabilities())

# Consume service by calling function, `addFunction`
# contained in this service
api_output <- api$addFunction(120, 2.8)

# Print response output
print(api_output$outputParameters$result)


##########################################################
#                 Update the webservice                  #
##########################################################

my_services <- listServices()

service <- my_services[[1]]
sname <- service$name
sversion <- service$version

api_new <- updateService(
  name = sname,
  v = sversion,
  code = "result <- x + y + z",
  inputs = list(x = "numeric", y = "numeric", z = "numeric"),
  outputs = list(result = "numeric")
)

api_new$capabilities()

api_output <- api$addFunction(120, 2, 5)

api_output$outputParameters$result
