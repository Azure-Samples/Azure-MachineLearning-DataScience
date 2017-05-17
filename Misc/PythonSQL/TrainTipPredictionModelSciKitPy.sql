
USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[TrainTipPredictionModelSciKitPy]    Script Date: 4/25/2017 11:36:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Split whole data into 60% training and 40% testing
DROP TABLE IF EXISTS dbo.nyctaxi_sample_training
SELECT * into nyctaxi_sample_training 
FROM nyctaxi_sample
  WHERE (ABS(CAST((BINARY_CHECKSUM(*) *RAND(98052)) as int)) % 100) < 60

DROP TABLE IF EXISTS dbo.nyctaxi_sample_testing
SELECT * into nyctaxi_sample_testing 
FROM nyctaxi_sample
WHERE (ABS(CAST((BINARY_CHECKSUM(*) *RAND(98052)) as int)) % 100) > 60


DROP PROCEDURE IF EXISTS TrainTipPredictionModelRxPy;
GO

CREATE PROCEDURE [dbo].[TrainTipPredictionModelRxPy] (@trained_model varbinary(max) OUTPUT)
AS
BEGIN
  EXEC sp_execute_external_script 
    @language = N'Python',
    @script = N'
import numpy
import pickle
import pandas
from revoscalepy.functions.RxLogit import rx_logit_ex;
from revoscalepy.functions.RxPredict import rx_predict_ex;

logitObj = rx_logit_ex("tipped ~ passenger_count + trip_distance + trip_time_in_secs + direct_distance", data = InputDataSet);

## Serialize model
trained_model = pickle.dumps(logitObj)
',
    @input_data_1 = N'
	select tipped, fare_amount, passenger_count, trip_time_in_secs, trip_distance, 
    dbo.fnCalculateDistance(pickup_latitude, pickup_longitude,  dropoff_latitude, dropoff_longitude) as direct_distance
    from nyctaxi_sample_training
	',
	@input_data_1_name = N'InputDataSet',
	@params = N'@trained_model varbinary(max) OUTPUT',
	@trained_model = @trained_model OUTPUT;
  ;
END;
GO

--Save model to table
DROP TABLE IF EXISTS nyc_taxi_models;
GO
CREATE TABLE nyc_taxi_models (
	name VARCHAR(30) NOT NULL DEFAULT('default model') PRIMARY KEY,
	model VARBINARY(MAX) NOT NULL
);
GO

TRUNCATE TABLE nyc_taxi_models;

DECLARE @model VARBINARY(MAX);
EXEC TrainTipPredictionModelRxPy @model OUTPUT;

INSERT INTO nyc_taxi_models (name, model) VALUES('rx_model', @model);
