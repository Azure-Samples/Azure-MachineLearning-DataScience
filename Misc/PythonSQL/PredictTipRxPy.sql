/****** Object:  StoredProcedure [dbo].[PredictTipSciKitPy]    Script Date: 5/17/2017 11:37:50 PM ******/

USE [TaxiNYC_Sample]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS PredictTipRxPy;
GO

CREATE PROCEDURE [dbo].[PredictTipRxPy] (@model varchar(50), @inquery nvarchar(max))
AS
BEGIN
  DECLARE @lmodel2 varbinary(max) = (select model from nyc_taxi_models where name = @model);

  EXEC sp_execute_external_script 
	@language = N'Python',
    @script = N'
import pickle
import numpy
import pandas
from sklearn import metrics
from revoscalepy.functions.RxPredict import rx_predict_ex

mod = pickle.loads(lmodel2)
X = InputDataSet[["passenger_count", "trip_distance", "trip_time_in_secs", "direct_distance"]]
y = numpy.ravel(InputDataSet[["tipped"]])

prob_array = rx_predict_ex(mod, X)
prob_list = list(prob_rrray._results["tipped_Pred"])

prob_array = numpy.asarray(prob_list)
fpr, tpr, thresholds = metrics.roc_curve(y, prob_array)
auc_result = metrics.auc(fpr, tpr)
print("AUC on testing data is:", auc_result)
OutputDataSet = pandas.DataFrame(data=prob_list, columns=["predictions"])
',	
	@input_data_1 = @inquery,
	@input_data_1_name = N'InputDataSet',
	@params = N'@lmodel2 varbinary(max)',
	@lmodel2 = @lmodel2
  WITH RESULT SETS ((Score float));

END
GO
