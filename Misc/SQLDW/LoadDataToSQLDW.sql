DECLARE @StorageAccountKey varchar(255)
SET @StorageAccountKey = 'x'

DECLARE @StorageAccountName varchar(255)
SET @StorageAccountName = 'x'

DECLARE @ContainerName varchar(255)
SET @ContainerName = 'x'


DECLARE @KeyAlias varchar(255)
SET @KeyAlias = 'x'

DECLARE @nyctaxi_trip_storage varchar(255)
SET @nyctaxi_trip_storage = 'x'

DECLARE @nyctaxi_fare_storage varchar(255)
SET @nyctaxi_fare_storage = 'x'

DECLARE @csv_file_format varchar(255)
SET @csv_file_format = 'x'

DECLARE @external_nyctaxi_trip varchar(255)
SET @external_nyctaxi_trip = 'x'

DECLARE @external_nyctaxi_fare varchar(255)
SET @external_nyctaxi_fare = 'x'

DECLARE @schemaname varchar(255)
SET @schemaname = 'x'

DECLARE @nyctaxi_trip varchar(255)
SET @nyctaxi_trip = 'x'

DECLARE @nyctaxi_fare varchar(255)
SET @nyctaxi_fare = 'x'

DECLARE @nyctaxi_sample varchar(255)
SET @nyctaxi_sample = 'x'

DECLARE @load_data_template varchar(8000)
SET @load_data_template = '

--Create a schema
--CREATE SCHEMA {schemaname}; 
EXEC (''CREATE SCHEMA {schemaname};'');

-- Create a database scoped credential
CREATE DATABASE SCOPED CREDENTIAL {KeyAlias} 
WITH IDENTITY = ''asbkey'' , 
Secret = ''{StorageAccountKey}''

-- Create an external data source for an Azure storage blob
CREATE EXTERNAL DATA SOURCE {nyctaxi_trip_storage} 
WITH
(
    TYPE = HADOOP,
    LOCATION =''wasbs://{ContainerName}@{StorageAccountName}.blob.core.windows.net'',
    CREDENTIAL = {KeyAlias}
)
;

CREATE EXTERNAL DATA SOURCE {nyctaxi_fare_storage} 
WITH
(
    TYPE = HADOOP,
    LOCATION =''wasbs://{ContainerName}@{StorageAccountName}.blob.core.windows.net'',
    CREDENTIAL = {KeyAlias}
)
;

-- Create an external file format for a csv file.
-- Data is uncompressed and fields are separated with the
-- pipe character.
CREATE EXTERNAL FILE FORMAT {csv_file_format} 
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
CREATE EXTERNAL TABLE {external_nyctaxi_fare}
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
    DATA_SOURCE = {nyctaxi_fare_storage},
    FILE_FORMAT = {csv_file_format},
	REJECT_TYPE = VALUE,
	REJECT_VALUE = 12     
)  


CREATE EXTERNAL TABLE {external_nyctaxi_trip}
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
    DATA_SOURCE = {nyctaxi_trip_storage},
    FILE_FORMAT = {csv_file_format},
    REJECT_TYPE = VALUE,
	REJECT_VALUE = 12         
)
-- Load data from Azure blob storage to SQL Data Warehouse 

CREATE TABLE {schemaname}.{nyctaxi_fare}
WITH 
(   
    CLUSTERED COLUMNSTORE INDEX,
	DISTRIBUTION = HASH(medallion)
)
AS 
SELECT * 
FROM   {external_nyctaxi_fare}
;

CREATE TABLE {schemaname}.{nyctaxi_trip}
WITH 
(   
    CLUSTERED COLUMNSTORE INDEX,
	DISTRIBUTION = HASH(medallion)
)
AS 
SELECT * 
FROM   {external_nyctaxi_trip}
;

--- Create sample table using Trip and Fare table
CREATE TABLE {schemaname}.{nyctaxi_sample}
WITH 
(   
    CLUSTERED COLUMNSTORE INDEX,
	DISTRIBUTION = HASH(medallion)
)
AS 
(
	    SELECT t.*, f.payment_type, f.fare_amount, f.surcharge, f.mta_tax, f.tolls_amount, f.total_amount, f.tip_amount,
		tipped = CASE WHEN (tip_amount > 0) THEN 1 ELSE 0 END,
		tip_class = CASE 
						WHEN (tip_amount = 0) THEN 0
                        WHEN (tip_amount > 0 AND tip_amount <= 5) THEN 1
                        WHEN (tip_amount > 5 AND tip_amount <= 10) THEN 2
                        WHEN (tip_amount > 10 AND tip_amount <= 20) THEN 3
                        ELSE 4
                    END
	    FROM {schemaname}.{nyctaxi_trip} t, {schemaname}.{nyctaxi_fare} f
    	WHERE datepart("mi",t.pickup_datetime) = 1
		AND t.medallion = f.medallion
    	AND   t.hack_license = f.hack_license
    	AND   t.pickup_datetime = f.pickup_datetime
    	AND   pickup_longitude <> ''0''
        AND   dropoff_longitude <> ''0''
)
;


'

DECLARE @sql_script  varchar(8000)
SET @sql_script = REPLACE(@load_data_template, '{StorageAccountName}', @StorageAccountName)
SET @sql_script = REPLACE(@sql_script, '{StorageAccountKey}', @StorageAccountKey)
SET @sql_script = REPLACE(@sql_script, '{ContainerName}', @ContainerName)
SET @sql_script = REPLACE(@sql_script, '{KeyAlias}', @KeyAlias)
SET @sql_script = REPLACE(@sql_script, '{nyctaxi_trip_storage}', @nyctaxi_trip_storage)
SET @sql_script = REPLACE(@sql_script, '{nyctaxi_fare_storage}', @nyctaxi_fare_storage)
SET @sql_script = REPLACE(@sql_script, '{csv_file_format}', @csv_file_format)
SET @sql_script = REPLACE(@sql_script, '{external_nyctaxi_trip}', @external_nyctaxi_trip)
SET @sql_script = REPLACE(@sql_script, '{external_nyctaxi_fare}', @external_nyctaxi_fare)
SET @sql_script = REPLACE(@sql_script, '{schemaname}', @schemaname)
SET @sql_script = REPLACE(@sql_script, '{nyctaxi_trip}', @nyctaxi_trip)
SET @sql_script = REPLACE(@sql_script, '{nyctaxi_fare}', @nyctaxi_fare)
SET @sql_script = REPLACE(@sql_script, '{nyctaxi_sample}', @nyctaxi_sample)


EXECUTE(@sql_script)
GO