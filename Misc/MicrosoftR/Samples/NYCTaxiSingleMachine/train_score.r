# train a model, score test examples, compute AUC
#################################################

# set up locations of input and output files
xdf_files <- ".\\xdf"
train_file <- file.path(xdf_files, "train.xdf")
test_file <- file.path(xdf_files, "test.xdf")
predictions_file <- file.path(xdf_files, "predictions.xdf")

# train a model
myformula <- formula(label ~ passenger_count + trip_distance + 
                             pickup_longitude + pickup_latitude + 
                             rate_code + dropoff_longitude + 
                             dropoff_latitude + fare_amount + mta_tax +
                             tolls_amount + surcharge + duration + weekday +  
                             F(hour))
logitModel <- rxLogit(formula = myformula, data = train_file, 
                      maxIterations = 1, reportProgress = 2, 
                      computeContext = rxGetComputeContext())

# scoring of test set
predictions <- rxPredict(logitModel, data = test_file, 
                         outData = predictions_file, 
                         writeModelVars = FALSE, overwrite = TRUE)

# compute AUC
predictionsDF <- rxImport(predictions_file)
pos.scores <- predictionsDF$label_Pred[labels$label == 1]
neg.scores <- predictionsDF$label_Pred[labels$label == 0]
auc <- mean(sample(pos.scores, 1000000, replace = TRUE) > sample(neg.scores, 1000000, replace = TRUE))
print(paste(“auc=”, auc, sep=””))
