# A script that runs a remote script
library(mrsdeploy)
remoteLogin("http://localhost:12800",
                        username = "admin",
                        password = "MLads2017!",
                        session = TRUE)
pause()
mrsdeploy::remoteScript("mtcars.R")
#remoteExecute("summary(rsqr)")
