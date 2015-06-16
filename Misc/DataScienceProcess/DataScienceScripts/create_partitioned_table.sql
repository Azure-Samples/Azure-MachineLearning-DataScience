USE TaxiNYC
go

-- Create partition function to set partition boundary by month
CREATE PARTITION FUNCTION PickupDatetimePFN(DATETIME)
AS RANGE RIGHT FOR VALUES (
    '20130201', '20130301', '20130401',
    '20130501', '20130601', '20130701', '20130801',
	'20130901', '20131001', '20131101', '20131201'
  )

-- Create partition scheme to send each partition to a different filegroup
CREATE PARTITION SCHEME PickupDatetimePScheme  AS
  PARTITION PickupDatetimePFN  TO (
  'nyctaxi_1', 'nyctaxi_2', 'nyctaxi_3', 'nyctaxi_4',
  'nyctaxi_5', 'nyctaxi_6', 'nyctaxi_7', 'nyctaxi_8',
  'nyctaxi_9', 'nyctaxi_10', 'nyctaxi_11', 'nyctaxi_12'
  )

-- Verify the newly created partition boundaries
SELECT psch.name as PartitionScheme,
prng.value AS ParitionValue,
prng.boundary_id AS BoundaryID
FROM sys.partition_functions AS pfun
INNER JOIN sys.partition_schemes psch ON pfun.function_id = psch.function_id
INNER JOIN sys.partition_range_values prng ON prng.function_id=pfun.function_id
WHERE pfun.name = 'PickupDatetimePFN'

-- Create a new table to hold NYC Taxi trip_data files
-- Table is partitioned according to partition scheme
CREATE TABLE nyctaxi_trip
(
       medallion varchar(50) not null,
       hack_license varchar(50)  not null,
       vendor_id char(3),
       rate_code char(3),
       store_and_fwd_flag char(3),
       pickup_datetime datetime  not null,
       dropoff_datetime datetime, 
       passenger_count int,
       trip_time_in_secs bigint,
       trip_distance float,
       pickup_longitude varchar(30),
       pickup_latitude varchar(30),
       dropoff_longitude varchar(30),
       dropoff_latitude varchar(30)
)
ON PickupDatetimePScheme(pickup_datetime)

-- Create a new table to hold NYC Taxi trip_fare files
-- Table is partitioned according to partition scheme
CREATE TABLE nyctaxi_fare
(
	medallion varchar(50) not null,
	hack_license varchar(50) not null,
	vendor_id char(3),
	pickup_datetime datetime not null,
	payment_type char(3),
	fare_amount float,
	surcharge float,
	mta_tax float,
	tip_amount float,
	tolls_amount float,
	total_amount float
)
ON PickupDatetimePScheme(pickup_datetime)
