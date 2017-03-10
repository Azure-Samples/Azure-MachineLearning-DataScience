setwd("/home/remoteuser/Code/MRS")
source("SetComputeContext.r")
startRxSpark()

finalData <- RxXdfData(file.path(dataDir, "joined5XDFSubset"))

################################################
# Split out Training and Test Datasets
################################################

# split out the training data

trainDS <- RxXdfData( file.path(dataDir, "finalDataTrainSubset" ))

rxDataStep( inData = finalData, outFile = trainDS,
            rowSelection = ( Year != 2012 ), overwrite = T )

# split out the testing data

testDS <- RxXdfData( file.path(dataDir, "finalDataTestSubset" ))

rxDataStep( inData = finalData, outFile = testDS,
            rowSelection = ( Year == 2012 ), overwrite = T )


################################################
# Train and Test a Logistic Regression model
################################################

formula <- as.formula(ArrDel15 ~ Month + DayofMonth + DayOfWeek + Carrier + OriginAirportID + 
                        DestAirportID + CRSDepTime + CRSArrTime + RelativeHumidityOrigin + 
                        AltimeterOrigin + DryBulbCelsiusOrigin + WindSpeedOrigin + 
                        VisibilityOrigin + DewPointCelsiusOrigin + RelativeHumidityDest + 
                        AltimeterDest + DryBulbCelsiusDest + WindSpeedDest + VisibilityDest + 
                        DewPointCelsiusDest
)

# Use the scalable rxLogit() function

logitModel <- rxLogit(formula, data = trainDS)

options(max.print = 10000)
base::summary(logitModel)

# Predict over test data (Logistic Regression).

logitPredict <- RxXdfData(file.path(dataDir, "logitPredictSubset"))

# Use the scalable rxPredict() function

rxPredict(logitModel, data = testDS, outData = logitPredict,
          extraVarsToWrite = c("ArrDel15"),
          type = 'response', overwrite = TRUE)

# Calculate ROC and Area Under the Curve (AUC).

logitRoc <- rxRoc("ArrDel15", "ArrDel15_Pred", logitPredict)
logitAuc <- rxAuc(logitRoc)

plot(logitRoc)

save(logitModel, file = "logitModelSubset.RData")

rxSparkDisconnect(rxGetComputeContext())
