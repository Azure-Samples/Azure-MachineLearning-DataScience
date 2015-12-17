DECLARE @StorageAccountKey varchar(255)
SET @StorageAccountKey = 'x'

DECLARE @StorageAccountName varchar(255)
SET @StorageAccountName = 'x'

DECLARE @ContainerName varchar(255)
SET @ContainerName = 'x'


--DECLARE @nyctaxi_fare_storage varchar(255)
--SET @nyctaxi_fare_storage = 'nyctaxi_fare_storage'

--DECLARE @nyctaxi_trip_storage varchar(255)
--SET @nyctaxi_trip_storage = 'nyctaxi_trip_storage'


--DECLARE @external_nyctaxi_fare varchar(255)
--DECLARE @external_nyctaxi_trip varchar(255)
--SET @external_nyctaxi_fare = 'external_nyctaxi_fare'
--SET @external_nyctaxi_trip = 'external_nyctaxi_trip'

--DECLARE @nyctaxi_fare varchar(255)
--DECLARE @nyctaxi_trip varchar(255)
--SET @nyctaxi_fare = 'nyctaxi_fare'
--SET @nyctaxi_trip = 'nyctaxi_trip'

-- Create a E master key
-- CREATE MASTER KEY;

-- Check for existing database-scoped credentials.
-- SELECT * FROM sys.database_credentials;


DECLARE @load_data_template varchar(8000)
SET @load_data_template = '
-- Create a database scoped credential
CREATE DATABASE SCOPED CREDENTIAL accountkey WITH IDENTITY = ''asbkey'' , Secret = ''{StorageAccountKey}''

-- Create an external data source for an Azure storage blob
CREATE EXTERNAL DATA SOURCE nyctaxi_fare_storage 
WITH
(
    TYPE = HADOOP,
    LOCATION =''wasbs://{ContainerName}@{StorageAccountName}.blob.core.windows.net'',
    CREDENTIAL = accountkey
)
;

CREATE EXTERNAL DATA SOURCE nyctaxi_trip_storage 
WITH
(
    TYPE = HADOOP,
    LOCATION =''wasbs://{ContainerName}@{StorageAccountName}.blob.core.windows.net'',
    CREDENTIAL = accountkey
)
;

-- Create an external file format for a csv file.
-- Data is uncompressed and fields are separated with the
-- pipe character.
CREATE EXTERNAL FILE FORMAT csv_file_format 
WITH 
(   
    FORMAT_TYPE = DELIMITEDTEXT, 
    FORMAT_OPTIONS  
    (
        FIELD_TERMINATOR ='','',
        USE_TYPE_DEFAULT = TRUE
    )
)
;

-- Creating an external table for data in Azure blob storage.
CREATE EXTERNAL TABLE external_nyctaxi_fare
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
with (
    LOCATION    = ''/nyctaxifare/'',
    DATA_SOURCE = nyctaxi_fare_storage,
    FILE_FORMAT = csv_file_format,
	REJECT_TYPE = VALUE,
	REJECT_VALUE = 12     
)  


CREATE EXTERNAL TABLE external_nyctaxi_trip
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
with (
    LOCATION    = ''/nyctaxitrip/'',
    DATA_SOURCE = nyctaxi_trip_storage,
    FILE_FORMAT = csv_file_format,
    REJECT_TYPE = VALUE,
	REJECT_VALUE = 12         
)
-- Load data from Azure blob storage to SQL Data Warehouse 

CREATE TABLE nyctaxi_fare
WITH 
(   
    CLUSTERED COLUMNSTORE INDEX,
	DISTRIBUTION = HASH(medallion)
)
AS 
SELECT * 
FROM   external_nyctaxi_fare
;

CREATE TABLE nyctaxi_trip
WITH 
(   
    CLUSTERED COLUMNSTORE INDEX,
	DISTRIBUTION = HASH(medallion)
)
AS 
SELECT * 
FROM   external_nyctaxi_trip
;
'

DECLARE @sql_script  varchar(8000)
SET @sql_script = REPLACE(@load_data_template, '{StorageAccountName}', @StorageAccountName)
SET @sql_script = REPLACE(@sql_script, '{StorageAccountKey}', @StorageAccountKey)
SET @sql_script = REPLACE(@sql_script, '{ContainerName}', @ContainerName)
EXECUTE(@sql_script)
GO