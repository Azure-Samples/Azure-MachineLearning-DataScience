#Create Hive database and tables
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
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' lines terminated by '\\n'
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
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' lines terminated by '\\n'
STORED AS TEXTFILE LOCATION 'wasb:///nyctaxidbdata/fare' TBLPROPERTIES('skip.header.line.count'='1');

#Load data to tables partition by partition. Replace 1 with 2, 3, ..., 12 for remaining months
LOAD DATA INPATH 'wasb:///nyctaxitripraw/trip_data_1.csv' INTO TABLE nyctaxidb.trip PARTITION (month=1);
LOAD DATA INPATH 'wasb:///nyctaxifareraw/trip_fare_1.csv' INTO TABLE nyctaxidb.fare PARTITION (month=1);

#Show databases in the Hadoop cluster
show databases;

#Show tables in database nyctaxidb
show tables in nyctaxidb;

#View the top 10 records in table trip
select * from nyctaxidb.trip where month=1 limit 10;

#View the top 10 records in table fare
select * from nyctaxidb.fare where month=1 limit 10;

#View the number of records in each of the 12 partitions
select month, count(*) from nyctaxidb.trip group by month;

#Trip distribution by medallion
SELECT medallion, COUNT(*) as med_count
FROM nyctaxidb.fare
WHERE month<=3
GROUP BY medallion
HAVING med_count > 100 
ORDER BY med_count desc;

#Trip distribution by medallion and hack_license
SELECT medallion, hack_license, COUNT(*) as trip_count
FROM nyctaxidb.fare
WHERE month=1
GROUP BY medallion, hack_license
HAVING trip_count > 100
ORDER BY trip_count desc;

#Data Quality Assessment: Verify records with invalid longitude and/or latitude
SELECT COUNT(*) FROM nyctaxidb.trip
WHERE month=1
    AND  (CAST(pickup_longitude AS float) NOT BETWEEN -90 AND 90
    OR    CAST(pickup_latitude AS float) NOT BETWEEN -90 AND 90
    OR    CAST(dropoff_longitude AS float) NOT BETWEEN -90 AND 90
    OR    CAST(dropoff_latitude AS float) NOT BETWEEN -90 AND 90
    OR    (pickup_longitude = '0' AND pickup_latitude = '0')
    OR    (dropoff_longitude = '0' AND dropoff_latitude = '0'));

#Exploration: Frequencies of tipped and not tipped trips
SELECT tipped, COUNT(*) AS tip_freq 
FROM 
(
    SELECT if(tip_amount > 0, 1, 0) as tipped, tip_amount
    FROM nyctaxidb.fare
)tc
GROUP BY tipped;

# Exploration: Frequencies of tip ranges
SELECT tip_class, COUNT(*) AS tip_freq 
FROM 
(
    SELECT if(tip_amount=0, 0, 
	   if(tip_amount>0 and tip_amount<=5, 1, 
	   if(tip_amount>5 and tip_amount<=10, 2, 
	   if(tip_amount>10 and tip_amount<=20, 3, 4)))) as tip_class, tip_amount
    FROM nyctaxidb.fare
)tc
GROUP BY tip_class;

#Exploration: Compute Direct Distance and Compare with Trip Distance
set R=3959;
set pi=radians(180);
select pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude, trip_distance, trip_time_in_secs,
    ${hiveconf:R}*2*2*atan((1-sqrt(1-pow(sin((dropoff_latitude-pickup_latitude)
    *${hiveconf:pi}/180/2),2)-cos(pickup_latitude*${hiveconf:pi}/180)
    *cos(dropoff_latitude*${hiveconf:pi}/180)*pow(sin((dropoff_longitude-pickup_longitude)*${hiveconf:pi}/180/2),2)))
    /sqrt(pow(sin((dropoff_latitude-pickup_latitude)*${hiveconf:pi}/180/2),2)
    +cos(pickup_latitude*${hiveconf:pi}/180)*cos(dropoff_latitude*${hiveconf:pi}/180)*
    pow(sin((dropoff_longitude-pickup_longitude)*${hiveconf:pi}/180/2),2))) as direct_distance 
from nyctaxi.trip 
where month=1 
    and pickup_longitude between -90 and -30
    and pickup_latitude between 30 and 90
    and dropoff_longitude between -90 and -30
    and dropoff_latitude between 30 and 90;

# Preparing Data for Model Building
select 
    t.medallion, 
    t.hack_license,
    t.vendor_id,
    t.rate_code,
    t.store_and_fwd_flag,
    t.pickup_datetime,
    t.dropoff_datetime,
    hour(t.pickup_datetime) as pickup_hour,
    weekofyear(t.pickup_datetime) as pickup_week,
    from_unixtime(unix_timestamp(t.pickup_datetime, 'yyyy-MM-dd HH:mm:ss'),'u') as weekday,
    t.passenger_count,
    t.trip_time_in_secs,
    t.trip_distance,
    t.pickup_longitude,
    t.pickup_latitude,
    t.dropoff_longitude,
    t.dropoff_latitude,
    f.payment_type, 
    f.fare_amount, 
    f.surcharge, 
    f.mta_tax, 
    f.tip_amount, 
    f.tolls_amount, 
    f.total_amount,
    if(tip_amount>0,1,0) as tipped,
    if(tip_amount=0,0,
    if(tip_amount>0 and tip_amount<=5,1,
    if(tip_amount>5 and tip_amount<=10,2,
    if(tip_amount>10 and tip_amount<=20,3,4)))) as tip_class
from
(
    select medallion, 
        hack_license,
        vendor_id,
        rate_code,
        store_and_fwd_flag,
        pickup_datetime,
        dropoff_datetime,
        passenger_count,
        trip_time_in_secs,
        trip_distance,
        pickup_longitude,
        pickup_latitude,
        dropoff_longitude,
        dropoff_latitude,
        rand() as sample_key 
    from nyctaxi.trip
    where pickup_latitude between 30 and 60
        and pickup_longitude between -90 and -60
        and dropoff_latitude between 30 and 60
        and dropoff_longitude between -90 and -60
)t
join
(
    select 
        medallion, 
        hack_license, 
	vendor_id, 
	pickup_datetime, 
	payment_type, 
	fare_amount, 
	surcharge, 
	mta_tax, 
	tip_amount, 
	tolls_amount, 
	total_amount
    from nyctaxi.fare 
)f
on t.medallion=f.medallion and t.hack_license=f.hack_license and t.pickup_datetime=f.pickup_datetime
where t.sample_key<=0.01;