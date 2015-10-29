USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[PredictTipWithPassedInValues]    Script Date: 10/29/2015 4:36:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PredictTipWithPassedInValues] @passenger_count int = 0,
@trip_distance float = 0,
@trip_time_in_secs int = 0,
@pickup_latitude float = 0,
@pickup_longitude float = 0,
@dropoff_latitude float = 0,
@dropoff_longitude float = 0
AS
BEGIN

  DECLARE @inquery nvarchar(max) = N'
  SELECT * FROM [TaxiNYC_Sample].[dbo].[fnEngineerFeatures]( '
  + CAST(@passenger_count AS varchar) + ', '
  + CAST(@trip_distance AS varchar) + ', '
  + CAST(@trip_time_in_secs AS varchar) + ', '
  + CAST(@pickup_latitude AS varchar) + ', '
  + CAST(@pickup_longitude AS varchar) + ', '
  + CAST(@dropoff_latitude AS varchar) + ', '
  + CAST(@dropoff_longitude AS varchar) + ')
	'
  DECLARE @lmodel2 varbinary(max) = (SELECT TOP 1
    model
  FROM nyc_taxi_models);
  EXEC sp_execute_external_script @language = N'R',
                                  @script = N'

mod <- unserialize(as.raw(model));
print(summary(mod))
OutputDataSet<-rxPredict(modelObject = mod, data = InputDataSet, outData = NULL, 
          predVarNames = "Score", type = "response", writeModelVars = FALSE, overwrite = TRUE);
str(OutputDataSet)
print(OutputDataSet)
',
                                  @input_data_1 = @inquery,
                                  @params = N'@model varbinary(max)',
                                  @model = @lmodel2
  WITH RESULT SETS ((Score float));

END


GO

