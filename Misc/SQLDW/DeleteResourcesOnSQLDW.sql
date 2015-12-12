DROP TABLE nyctaxi_fare
DROP TABLE nyctaxi_trip
DROP EXTERNAL TABLE external_nyctaxi_fare
DROP EXTERNAL TABLE external_nyctaxi_trip

DROP EXTERNAL DATA SOURCE nyctaxi_trip_storage
DROP EXTERNAL DATA SOURCE nyctaxi_fare_storage
DROP EXTERNAL FILE FORMAT csv_file_format
DROP DATABASE SCOPED CREDENTIAL accountkey