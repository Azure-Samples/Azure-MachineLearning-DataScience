DECLARE @db_name varchar(255), @tb_name varchar(255)
DECLARE @create_db_template varchar(max), @create_tb_template varchar(max), @create_tb_template2 varchar(max)
DECLARE @sql_script varchar(max)
SET @db_name = 'TaxiNYC_Sample' 
SET @tb_name = 'nyctaxi_sample' 
SET @create_db_template = 'create database {db_name}'
SET @create_tb_template = '
use {db_name}
CREATE TABLE {tb_name}
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
       dropoff_latitude varchar(30),
       payment_type char(3),
       fare_amount float,
       surcharge float,
       mta_tax float,
       tolls_amount float,
       total_amount float,
       tip_amount float,
       tipped int,
       tip_class int
)
CREATE CLUSTERED COLUMNSTORE INDEX [nyc_cci] ON {tb_name} WITH (DROP_EXISTING = OFF)
'

SET @create_tb_template2 = '
use {db_name}
CREATE TABLE nyc_taxi_models
(
  name varchar(250), 
  model varbinary(max) not null
)
'

-- Create database
SET @sql_script = REPLACE(@create_db_template, '{db_name}', @db_name)
EXECUTE(@sql_script)

-- Create table
SET @sql_script = REPLACE(@create_tb_template, '{db_name}', @db_name)
SET @sql_script = REPLACE(@sql_script, '{tb_name}', @tb_name)
EXECUTE(@sql_script)

-- Create the table to persist the trained model
SET @sql_script = REPLACE(@create_tb_template2, '{db_name}', @db_name)
EXECUTE(@sql_script)
GO
