USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[PredictTipSciKitPy]    Script Date: 4/25/2017 11:37:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PredictTipSciKitPy] @inquery nvarchar(max)
AS
BEGIN

  DECLARE @lmodel2 varbinary(max) = (SELECT TOP 1
    model
  FROM nyc_taxi_models);
  EXEC sp_execute_external_script @language = N'Python',
                                  @script = N'
import pickle;
import numpy;
import pandas;
from sklearn import metrics

mod = pickle.loads(model)

X = InputDataSet[["passenger_count", "trip_distance", "trip_time_in_secs", "direct_distance"]]
y = numpy.ravel(InputDataSet[["tipped"]])

probArray = mod.predict_proba(X)
probList = []
for i in range(len(probArray)):
    probList.append((probArray[i])[1])

probArray = numpy.asarray(probList)
fpr, tpr, thresholds = metrics.roc_curve(y, probArray)
aucResult = metrics.auc(fpr, tpr)
print ("AUC is: " + str(aucResult))

OutputDataSet = pandas.DataFrame(data = probList, columns = ["predictions"])
',
                                  @input_data_1 = @inquery,
                                  @params = N'@model varbinary(max)',
                                  @model = @lmodel2
  WITH RESULT SETS ((Score float));

END

GO