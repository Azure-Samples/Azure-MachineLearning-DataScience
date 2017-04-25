USE [TaxiNYC_Sample]
GO

/****** Object:  UserDefinedFunction [dbo].[fnEngineerFeatures]    Script Date: 10/29/2015 4:36:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type IN ('FN', 'IF') AND name = 'fnEngineerFeatures')
  DROP FUNCTION fnEngineerFeatures
GO

CREATE FUNCTION [dbo].[fnEngineerFeatures] (
@passenger_count int = 0,
@trip_distance float = 0,
@trip_time_in_secs int = 0,
@pickup_latitude float = 0,
@pickup_longitude float = 0,
@dropoff_latitude float = 0,
@dropoff_longitude float = 0)
RETURNS TABLE
AS
  RETURN
  (
  -- Add the SELECT statement with parameter references here
  SELECT
    @passenger_count AS passenger_count,
    @trip_distance AS trip_distance,
    @trip_time_in_secs AS trip_time_in_secs,
    [dbo].[fnCalculateDistance](@pickup_latitude, @pickup_longitude, @dropoff_latitude, @dropoff_longitude) AS direct_distance

  )
GO