#Get the count of observations per partition 
SELECT <partitionfieldname>, count(*) from <databasename>.<tablename> group by <partitionfieldname>;

#Get the count of observations per day 
SELECT to_date(<date_columnname>), count(*) from <databasename>.<tablename> group by to_date(<date_columnname>);

#Get the levels in a categorical column
SELECT distinct <column_name> from <databasename>.<tablename>

#Get the number of levels in combination of two categorical columns 
SELECT <column_a>, <column_b>, count(*) from <databasename>.<tablename> group by <column_a>, <column_b>

#Get the distribution for numerical columns
SELECT <column_name>, count(*) from <databasename>.<tablename> group by <column_name>

#Extract records from joining two tables
SELECT 
    a.<common_columnname1> as <new_name1>,
    a.<common_columnname2> as <new_name2>,
    a.<a_column_name1> as <new_name3>,
    a.<a_column_name2> as <new_name4>,
    b.<b_column_name1> as <new_name5>,
    b.<b_column_name2> as <new_name6>
FROM
    (
    SELECT <common_columnname1>, 
        <common_columnname2>,
        <a_column_name1>,
        <a_column_name2>,
    FROM <databasename>.<tablename1>
    ) a
    join
    (
    SELECT <common_columnname1>, 
        <common_columnname2>,
        <b_column_name1>,
        <b_column_name2>,
    FROM <databasename>.<tablename2>
    ) b
ON a.<common_columnname1>=b.<common_columnname1> and a.<common_columnname2>=b.<common_columnname2>;

#Frequency based feature generation
select 
    a.<column_name1>, a.<column_name2>, a.sub_count/sum(a.sub_count) over () as frequency
from
(
    select 
        <column_name1>,<column_name2>, count(*) as sub_count 
    from <databasename>.<tablename> group by <column_name1>, <column_name2>
)a
order by frequency desc;

#Risks of categorical variables in binary classification
set smooth_param1=1;
set smooth_param2=20;
select 
    <column_name1>,<column_name2>, 
    ln((sum_target+${hiveconf:smooth_param1})/(record_count-sum_target+${hiveconf:smooth_param2}-${hiveconf:smooth_param1})) as risk
from
(
    select 
        <column_nam1>, <column_name2>, sum(binary_target) as sum_target, sum(1) as record_count
    from
    (
        select 
            <column_name1>, <column_name2>, if(target_column>0,1,0) as binary_target
        from <databasename>.<tablename> 
    )a
    group by <column_name1>, <column_name2>
)b;

#Extract features from datetime field
select day(<datetime field>), month(<datetime field>) 
from <databasename>.<tablename>;

#Extract features from text field
select length(<text field>) as str_len, size(split(<text field>,' ')) as word_num 
from <databasename>.<tablename>;

#Calculate direct distance from two GPS coordinates (NYC Taxi Trip Data Specific)
set R=3959;
set pi=radians(180);
select pickup_longitude, pickup_latitude, dropoff_longitude, dropoff_latitude, 
    ${hiveconf:R}*2*2*atan((1-sqrt(1-pow(sin((dropoff_latitude-pickup_latitude)
    *${hiveconf:pi}/180/2),2)-cos(pickup_latitude*${hiveconf:pi}/180)
    *cos(dropoff_latitude*${hiveconf:pi}/180)*pow(sin((dropoff_longitude-pickup_longitude)*${hiveconf:pi}/180/2),2)))
    /sqrt(pow(sin((dropoff_latitude-pickup_latitude)*${hiveconf:pi}/180/2),2)
    +cos(pickup_latitude*${hiveconf:pi}/180)*cos(dropoff_latitude*${hiveconf:pi}/180)*
    pow(sin((dropoff_longitude-pickup_longitude)*${hiveconf:pi}/180/2),2))) as direct_distance 
from nyctaxi.trip 
where pickup_longitude between -90 and 0
    and pickup_latitude between 30 and 90
    and dropoff_longitude between -90 and 0
    and dropoff_latitude between 30 and 90
limit 10; 