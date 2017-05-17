/****** Object:  StoredProcedure [dbo].[PredictTipSciKitPy]    Script Date: 5/17/2017 11:37:50 PM ******/

USE [TaxiNYC_Sample]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


DROP PROCEDURE IF EXISTS PredictTipSciKitPy;
GO

CREATE PROCEDURE [dbo].[PredictTipSciKitPy] (@model varchar(100))
AS
BEGIN
  DECLARE @lmodel2 varbinary(max) = (select model from nyc_taxi_models where name = @model);

  EXEC sp_execute_external_script 
	@language = N'Python',
    @script = N'
import pickle;
import numpy;
import pandas;
from sklearn import metrics

mod = pickle.loads(lmodel2)

X = InputDataSet[["passenger_count", "trip_distance", "trip_time_in_secs", "direct_distance"]]
y = numpy.ravel(InputDataSet[["tipped"]])

probArray = mod.predict_proba(X)
probList = []
for i in range(len(probArray)):
	probList.append((probArray[i])[1])

probArray = numpy.asarray(probList)
fpr, tpr, thresholds = metrics.roc_curve(y, probArray)
aucResult = metrics.auc(fpr, tpr)
print ("AUC on testing data is: " + str(aucResult))

OutputDataSet = pandas.DataFrame(data = probList, columns = ["predictions"])
',	
	@input_data_1 = N'select tipped, fare_amount, passenger_count, trip_time_in_secs, trip_distance,
					dbo.fnCalculateDistance(pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude) as direct_distance
					from nyctaxi_sample_testing
					',
	@input_data_1_name = N'InputDataSet',
	@params = N'@lmodel2 varbinary(max)',
	@lmodel2 = @lmodel2
  WITH RESULT SETS ((Score float));

END
GO

--Call stored procedure
EXEC [dbo].[PredictTipSciKitPy] 'linear_model';  
