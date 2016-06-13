n_cores <- 8
rxSetComputeContext(RxLocalParallel())
rxOptions(numCoresToUse=8)

xdf_files <- ".\\xdf"
train_file <- file.path(xdf_files, "train.xdf")
test_file <- file.path(xdf_files, "test.xdf")

predictions_file <- file.path(xdf_files, "predictions.xdf")

myformula <- formula(label ~ passenger_count + trip_distance + 
                             pickup_longitude + pickup_latitude + 
                             rate_code + dropoff_longitude + 
                             dropoff_latitude + fare_amount + mta_tax +
                             tolls_amount + surcharge + duration + weekday +  
                             F(hour))

logitModel <- rxLogit(formula = myformula, data = train_file, 
                      maxIterations = 1, reportProgress = 2, 
                      computeContext = rxGetComputeContext())

predictions <- rxPredict(logitModel, data = test_file, 
                         outData = predictions_file, 
                         writeModelVars = FALSE, overwrite = TRUE)

predictionsDF <- rxImport(predictions_file)

# compute AUC
pos.scores <- predictionsDF$label_Pred[labels$label == 1]
neg.scores <- predictionsDF$label_Pred[labels$label == 0]
auc <- mean(sample(pos.scores,100000,replace=T) >           
            sample(neg.scores,100000,replace=T))
print(paste(“auc=”,auc,sep=””))
