USE [TaxiNYC]
go

-- Report number of rows in table nyctaxi_trip without table scan
SELECT SUM(rows) FROM sys.partitions WHERE object_id = OBJECT_ID('nyctaxi_trip')

-- Report number of columns in table nyctaxi_trip
SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'nyctaxi_trip' 

-- Report the number of rows per partition
SELECT partition_number, SUM(rows) FROM sys.partitions WHERE object_id = OBJECT_ID('nyctaxi_trip')
GROUP BY partition_number
ORDER BY partition_number

-- Count number of trips tipped vs. NOT tipped
SELECT tipped, COUNT(*) AS tip_freq FROM (
  SELECT CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END AS tipped, tip_amount
  FROM nyctaxi_fare
  WHERE pickup_datetime BETWEEN '20130101' AND '20130131') tc
GROUP BY tipped
go

-- Count number of trips per tip amount range ($0, $0-$5, $10-$20, >$20)
SELECT tip_class, COUNT(*) AS tip_freq FROM (
SELECT CASE 
	WHEN (tip_amount = 0) THEN 0
	WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
	WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
	WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
	ELSE 4 
	END AS tip_class
  FROM nyctaxi_fare
  WHERE pickup_datetime BETWEEN '20130101' AND '20130131') tc
GROUP BY tip_class
go

-- Count number of trips per medallion
SELECT medallion, COUNT(*)
FROM nyctaxi_fare
WHERE pickup_datetime BETWEEN '20130101' AND '20130131'
GROUP BY medallion
HAVING COUNT(*) > 100
go

-- Count number of trips per hack_license
SELECT hack_license, COUNT(*)
FROM nyctaxi_fare
WHERE pickup_datetime BETWEEN '20130101' AND '20130131'
GROUP BY hack_license
HAVING COUNT(*) > 100
go

-- Count number of trips per medallion AND hack_license
SELECT medallion, hack_license, COUNT(*)
FROM nyctaxi_fare
WHERE pickup_datetime BETWEEN '20130101' AND '20130131'
GROUP BY medallion, hack_license
HAVING COUNT(*) > 100
go

-- Assess data quality - Check incorrect coordinates
SELECT COUNT(*) FROM nyctaxi_trip
WHERE pickup_datetime BETWEEN '20130101' AND '20130331'
AND  (CAST(pickup_longitude AS float) NOT BETWEEN -90 AND 90
OR    CAST(pickup_latitude AS float) NOT BETWEEN -90 AND 90
OR    CAST(dropoff_longitude AS float) NOT BETWEEN -90 AND 90
OR    CAST(dropoff_latitude AS float) NOT BETWEEN -90 AND 90
OR    (pickup_longitude = '0' AND pickup_latitude = '0')
OR    (dropoff_longitude = '0' AND dropoff_latitude = '0'))
go

-- Convert to geography AND compute distance
SELECT 
    pickup_longitude
    ,pickup_latitude
	,dropoff_longitude
	,dropoff_latitude
	,pickup_location=geography::STPointFromText('POINT(' + pickup_longitude + ' ' + pickup_latitude + ')', 4326)
	,pickup_locstr=geography::STPointFromText('POINT(' + pickup_longitude + ' ' + pickup_latitude + ')', 4326).ToString()
	,dropoff_location=geography::STPointFromText('POINT(' + dropoff_longitude + ' ' + dropoff_latitude + ')', 4326)
	,dropoff_locstr=geography::STPointFromText('POINT(' + dropoff_longitude + ' ' + dropoff_latitude + ')', 4326).ToString()
	,trip_distance
	,computedist=round(geography::STPointFromText('POINT(' + pickup_longitude + ' ' + pickup_latitude + ')', 4326).STDistance(geography::STPointFromText('POINT(' + dropoff_longitude + ' ' + dropoff_latitude + ')', 4326))/1000, 2)
FROM nyctaxi_trip
tablesample(0.01 percent)
WHERE CAST(pickup_latitude AS float) BETWEEN -90 AND 90
AND   CAST(dropoff_latitude AS float) BETWEEN -90 AND 90
AND   pickup_longitude != '0' AND dropoff_longitude != '0'
go

-- View 1000 records of the joined tables
SELECT top 1000 t.*, f.*
FROM nyctaxi_trip t, nyctaxi_fare f
WHERE t.medallion = f.medallion
AND   t.hack_license = f.hack_license
AND   t.pickup_datetime = f.pickup_datetime
go

-- Example of query fOR joining data + creating labels AND features + down sampling
-- Suitable to use directly in Azure ML
SELECT t.*, f.payment_type, f.fare_amount, f.surcharge, f.mta_tax, f.tolls_amount, f.total_amount, f.tip_amount,
    CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END AS tipped,
    CASE WHEN (tip_amount = 0) THEN 0
        WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
        WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
        WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
        ELSE 4
    END AS tip_class
FROM nyctaxi_trip t, nyctaxi_fare f
tablesample (1 percent)
WHERE t.medallion = f.medallion
AND   t.hack_license = f.hack_license
AND   t.pickup_datetime = f.pickup_datetime
AND   pickup_longitude != '0' AND dropoff_longitude != '0'
go

-- Example of query fOR joining data + creating labels AND features + down sampling
-- Suitable to use directly in Azure ML
-- Exclude incorrect coordinates
SELECT t.*, f.payment_type, f.fare_amount, f.surcharge, f.mta_tax, f.tolls_amount, f.total_amount, f.tip_amount,
    CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END AS tipped,
    CASE WHEN (tip_amount = 0) THEN 0
        WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
        WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
        WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
        ELSE 4
    END AS tip_class
FROM nyctaxi_trip t, nyctaxi_fare f
tablesample (1 percent)
WHERE t.medallion = f.medallion
AND   t.hack_license = f.hack_license
AND   t.pickup_datetime = f.pickup_datetime
AND   CAST(pickup_latitude AS float) BETWEEN -90 AND 90
AND   CAST(dropoff_latitude AS float) BETWEEN -90 AND 90
AND   pickup_longitude != '0' AND dropoff_longitude != '0'
go

