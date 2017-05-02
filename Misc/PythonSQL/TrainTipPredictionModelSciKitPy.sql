USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[TrainTipPredictionModelSciKitPy]    Script Date: 4/25/2017 11:36:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[TrainTipPredictionModelSciKitPy]

AS
BEGIN
  DECLARE @inquery nvarchar(max) = N'
	select tipped, fare_amount, passenger_count, trip_time_in_secs, trip_distance, 
    dbo.fnCalculateDistance(pickup_latitude, pickup_longitude,  dropoff_latitude, dropoff_longitude) as direct_distance
    from nyctaxi_sample
    tablesample (70 percent) repeatable (98052)
'
  -- Insert the trained model into a database table
  INSERT INTO nyc_taxi_models
  EXEC sp_execute_external_script @language = N'Python',
                                  @script = N'

from sklearn.linear_model import LogisticRegression
import numpy
import pickle

## Create model
X = InputDataSet[["passenger_count", "trip_distance", "trip_time_in_secs", "direct_distance"]]
y = numpy.ravel(InputDataSet[["tipped"]])

SKLalgo = LogisticRegression()
logitObj = SKLalgo.fit(X, y)

## Serialize model and put it in data frame
trained_model = pandas.DataFrame(data = [pickle.dumps(logitObj)], columns = ["model"])
',
                                  @input_data_1 = @inquery,
                                  @output_data_1_name = N'trained_model'
  ;

END

GO
