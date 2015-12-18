	-- Report number of rows in table <nyctaxi_trip> without table scan
	SELECT SUM(rows) FROM sys.partitions WHERE object_id = OBJECT_ID('<nyctaxi_trip>')

	-- Report number of columns in table <nyctaxi_trip>
	SELECT COUNT(*) FROM information_schema.columns WHERE table_name = '<nyctaxi_trip>'

	-- Exploration: Trip distribution by medallion
	SELECT medallion, COUNT(*)
	FROM <nyctaxi_fare>
	WHERE pickup_datetime BETWEEN '20130101' AND '20130331'
	GROUP BY medallion
	HAVING COUNT(*) > 100

	-- Exploration: Trip distribution by medallion and hack_license
	SELECT medallion, hack_license, COUNT(*)
	FROM <nyctaxi_fare>
	WHERE pickup_datetime BETWEEN '20130101' AND '20130131'
	GROUP BY medallion, hack_license
	HAVING COUNT(*) > 100

	-- Data Quality Assessment: Verify records with incorrect longitude and/or latitude
	SELECT COUNT(*) FROM <nyctaxi_trip>
	WHERE pickup_datetime BETWEEN '20130101' AND '20130331'
	AND  (CAST(pickup_longitude AS float) NOT BETWEEN -90 AND 90
	OR    CAST(pickup_latitude AS float) NOT BETWEEN -90 AND 90
	OR    CAST(dropoff_longitude AS float) NOT BETWEEN -90 AND 90
	OR    CAST(dropoff_latitude AS float) NOT BETWEEN -90 AND 90
	OR    (pickup_longitude = '0' AND pickup_latitude = '0')
	OR    (dropoff_longitude = '0' AND dropoff_latitude = '0'))

	-- Exploration: Tipped vs. Not Tipped Trips distribution
	SELECT tipped, COUNT(*) AS tip_freq FROM (
	  SELECT CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END AS tipped, tip_amount
	  FROM <nyctaxi_fare>
	  WHERE pickup_datetime BETWEEN '20130101' AND '20131231') tc
	GROUP BY tipped

	-- Exploration: Tip Class/Range Distribution
	SELECT tip_class, COUNT(*) AS tip_freq FROM (
		SELECT CASE
			WHEN (tip_amount = 0) THEN 0
			WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
			WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
			WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
			ELSE 4
		END AS tip_class
	FROM <nyctaxi_fare>
	WHERE pickup_datetime BETWEEN '20130101' AND '20131231') tc
	GROUP BY tip_class

	-- Exploration: Compute and Compare Trip Distance
	/****** Object:  UserDefinedFunction [dbo].[fnCalculateDistance] ******/
	SET ANSI_NULLS ON
	GO

	SET QUOTED_IDENTIFIER ON
	GO

	IF EXISTS (SELECT * FROM sys.objects WHERE type IN ('FN', 'IF') AND name = 'fnCalculateDistance')
	  DROP FUNCTION fnCalculateDistance
	GO

	-- User-defined function calculate the direct distance between two geographical coordinates.
	CREATE FUNCTION [dbo].[fnCalculateDistance] (@Lat1 float, @Long1 float, @Lat2 float, @Long2 float)
	
	RETURNS float
	AS
	BEGIN
	  	DECLARE @distance decimal(28, 10)
  		-- Convert to radians
  		SET @Lat1 = @Lat1 / 57.2958
  		SET @Long1 = @Long1 / 57.2958
  		SET @Lat2 = @Lat2 / 57.2958
  		SET @Long2 = @Long2 / 57.2958
  		-- Calculate distance
  		SET @distance = (SIN(@Lat1) * SIN(@Lat2)) + (COS(@Lat1) * COS(@Lat2) * COS(@Long2 - @Long1))
  		--Convert to miles
  		IF @distance <> 0
  		BEGIN
    		SET @distance = 3958.75 * ATAN(SQRT(1 - POWER(@distance, 2)) / @distance);
  		END
  		RETURN @distance
	END
	GO

	-- Sample query to call the function to create features
	SELECT pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude, 
	dbo.fnCalculateDistance(pickup_latitude, pickup_longitude, dropoff_latitude, dropoff_longitude) AS DirectDistance
	FROM <nyctaxi_trip>
	WHERE datepart("mi",pickup_datetime)=1
	AND CAST(pickup_latitude AS float) BETWEEN -90 AND 90
	AND CAST(dropoff_latitude AS float) BETWEEN -90 AND 90
	AND pickup_longitude != '0' AND dropoff_longitude != '0'

	-- Preparing Data for Model Building
	SELECT t.*, f.payment_type, f.fare_amount, f.surcharge, f.mta_tax, f.tolls_amount, 	f.total_amount, f.tip_amount,
	    CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END AS tipped,
	    CASE WHEN (tip_amount = 0) THEN 0
	        WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
	        WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
	        WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
	        ELSE 4
	    END AS tip_class
	FROM <nyctaxi_trip> t, <nyctaxi_fare> f
	WHERE datepart("mi",t.pickup_datetime) = 1
	AND   t.medallion = f.medallion
	AND   t.hack_license = f.hack_license
	AND   t.pickup_datetime = f.pickup_datetime
	AND   pickup_longitude != '0' AND dropoff_longitude != '0'

	-- Persist query results in a sample table
	CREATE TABLE <nyctaxi_sample>
	WITH 
	(   
	    CLUSTERED COLUMNSTORE INDEX,
		DISTRIBUTION = HASH(medallion)
	)
	AS 
	(
	    SELECT t.*, f.payment_type, f.fare_amount, f.surcharge, f.mta_tax, f.tolls_amount, f.total_amount, f.tip_amount,
		tipped = CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END,
		tip_class = CASE WHEN (tip_amount = 0) THEN 0
                        WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
                        WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
                        WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
                        ELSE 4
                    END
	    FROM <nyctaxi_trip> t, <nyctaxi_fare> f
    	WHERE datepart("mi",t.pickup_datetime) = 1
	AND t.medallion = f.medallion
    	AND   t.hack_license = f.hack_license
    	AND   t.pickup_datetime = f.pickup_datetime
    	AND   pickup_longitude <> '0' AND dropoff_longitude <> '0'
	)