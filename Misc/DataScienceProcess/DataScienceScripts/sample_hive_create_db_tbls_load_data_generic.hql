# Create Hive database and tables
create database if not exists <database name>;
CREATE EXTERNAL TABLE if not exists <database name>.<table name>
(
	field1 string, 
	field2 int, 
	field3 float, 
	field4 double, 
	...,
	fieldN string
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY '<field separator>' lines terminated by '<line separator>' 
STORED AS TEXTFILE LOCATION '<storage location>' TBLPROPERTIES("skip.header.line.count"="1");

# Load data into Hive tables
LOAD DATA INPATH '<path to blob data>' INTO TABLE <database name>.<table name>;

# Create partitioned Hive tables and load data by partition
CREATE EXTERNAL TABLE IF NOT EXISTS <database name>.<table name>
(
	field1 string,
	...
	fieldN string
)
PARTITIONED BY (<partitionfieldname> vartype) ROW FORMAT DELIMITED FIELDS TERMINATED BY '<field separator>'
	lines terminated by '<line separator>' TBLPROPERTIES("skip.header.line.count"="1");
LOAD DATA INPATH '<path to the source file>' INTO TABLE <database name>.<partitioned table name> 
	PARTITION (<partitionfieldname>=<partitionfieldvalue>);

# Query from Hive tables with partitions
select 
	field1, field2, ..., fieldN
from <database name>.<partitioned table name> 
where <partitionfieldname>=<partitionfieldvalue> and ...;

# Store Hive data in ORC format
##First, create a table stored as textfile and load data to the table
CREATE EXTERNAL TABLE IF NOT EXISTS <database name>.<external textfile table name>
(
	field1 string,
	field2 int,
	...
	fieldN date
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '<field separator>' 
	lines terminated by '<line separator>' STORED AS TEXTFILE 
	LOCATION 'wasb:///<directory in Azure blob>' TBLPROPERTIES("skip.header.line.count"="1");

LOAD DATA INPATH '<path to the source file>' INTO TABLE <database name>.<table name>;

##Second, create a table stored as ORC.
CREATE TABLE IF NOT EXISTS <database name>.<ORC table name> 
(
	field1 string,
	field2 int,
	...
	fieldN date
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY '<field separator>' STORED AS ORC;

##Third, insert the records from the textfile format table to the ORC format table
INSERT OVERWRITE TABLE <database name>.<ORC table name> SELECT * FROM <database name>.<external textfile table name>;

##Finally, drop the textfile format table to save storage
DROP TABLE IF EXISTS <database name>.<external textfile table name>;