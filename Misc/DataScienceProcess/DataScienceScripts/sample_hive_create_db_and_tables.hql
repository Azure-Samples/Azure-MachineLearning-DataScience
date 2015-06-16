	create database if not exists nyctaxidb;

	create external table if not exists nyctaxidb.trip
	( 
	    medallion string, 
	    hack_license string,
	    vendor_id string, 
	    rate_code string, 
	    store_and_fwd_flag string, 
	    pickup_datetime string, 
	    dropoff_datetime string, 
	    passenger_count int, 
	    trip_time_in_secs double, 
	    trip_distance double, 
	    pickup_longitude double, 
	    pickup_latitude double, 
	    dropoff_longitude double, 
	    dropoff_latitude double)  
	PARTITIONED BY (month int) 
	ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' lines terminated by '\n'
	STORED AS TEXTFILE LOCATION 'wasb:///nyctaxidbdata/trip' TBLPROPERTIES('skip.header.line.count'='1');

	create external table if not exists nyctaxidb.fare 
	( 
	    medallion string, 
	    hack_license string, 
	    vendor_id string, 
	    pickup_datetime string, 
	    payment_type string, 
	    fare_amount double, 
	    surcharge double,
	    mta_tax double,
	    tip_amount double,
	    tolls_amount double,
	    total_amount double)
	PARTITIONED BY (month int) 
	ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' lines terminated by '\n'
	STORED AS TEXTFILE LOCATION 'wasb:///nyctaxidbdata/fare' TBLPROPERTIES('skip.header.line.count'='1');