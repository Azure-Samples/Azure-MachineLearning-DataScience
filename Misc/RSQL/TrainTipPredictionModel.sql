USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[TrainTipPredictionModel]    Script Date: 10/29/2015 4:36:25 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'TrainTipPredictionModel')
  DROP PROCEDURE TrainTipPredictionModel
GO


CREATE PROCEDURE [dbo].[TrainTipPredictionModel]

AS
BEGIN
  DECLARE @inquery nvarchar(max) = N'
	select tipped, fare_amount, passenger_count,trip_time_in_secs,trip_distance, 
    pickup_datetime, dropoff_datetime, 
    dbo.fnCalculateDistance(pickup_latitude, pickup_longitude,  dropoff_latitude, dropoff_longitude) as direct_distance
    from nyctaxi_sample
    tablesample (70 percent) repeatable (98052)
'
  -- Insert the trained model into a database table
  INSERT INTO nyc_taxi_models
  EXEC sp_execute_external_script @language = N'R',
                                  @script = N'

## Create model
logitObj <- rxLogit(tipped ~ passenger_count + trip_distance + trip_time_in_secs + direct_distance, data = InputDataSet)
summary(logitObj)

## Serialize model and put it in data frame
trained_model <- data.frame(model=as.raw(serialize(logitObj, NULL)));
',
                                  @input_data_1 = @inquery,
                                  @output_data_1_name = N'trained_model'
  ;

END
GO

