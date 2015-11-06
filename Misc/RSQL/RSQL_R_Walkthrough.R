library(RevoScaleR)
# connection string
# currently we use SQL authentication
connStr <- "Driver=SQL Server;Server=<your_server_name.somedomain.com>;Database=<Your_Database_Name>;Uid=<Your_User_Name>;Pwd=<Your_Password>"

# set ComputeContext
sqlShareDir <- paste("C:\\AllShare\\",Sys.getenv("USERNAME"),sep="")
sqlWait <- TRUE
sqlConsoleOutput <- FALSE
cc <- RxInSqlServer(connectionString = connStr, shareDir = sqlShareDir, 
                    wait = sqlWait, consoleOutput = sqlConsoleOutput)
rxSetComputeContext(cc)