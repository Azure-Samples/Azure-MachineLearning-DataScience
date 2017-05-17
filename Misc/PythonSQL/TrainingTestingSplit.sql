USE [TaxiNYC_Sample]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Split whole data into training and testing, specify an integer as the parameter of the stored procedure

DROP PROCEDURE IF EXISTS TrainTestSplit;
GO

CREATE PROCEDURE [dbo].[TrainTestSplit] (@pct int)
AS

DROP TABLE IF EXISTS dbo.nyctaxi_sample_training
SELECT * into nyctaxi_sample_training 
FROM nyctaxi_sample
WHERE (ABS(CAST(BINARY_CHECKSUM(medallion,hack_license)  as int)) % 100) <= @pct

DROP TABLE IF EXISTS dbo.nyctaxi_sample_testing
SELECT * into nyctaxi_sample_testing 
FROM nyctaxi_sample
WHERE (ABS(CAST(BINARY_CHECKSUM(medallion,hack_license)  as int)) % 100) > @pct

GO

EXEC TrainTestSplit 60
GO
