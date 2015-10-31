USE [TaxiNYC_Sample]
GO

/****** Object:  StoredProcedure [dbo].[PredictTip]    Script Date: 10/29/2015 4:36:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[PredictTip] @inquery nvarchar(max)
AS
BEGIN

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