-- Create a new index for the NYC Taxi trip data table
-- Index is partitioned according to partition scheme
create index nyctaxi_trip_idx on nyctaxi_trip(medallion, hack_license, pickup_datetime)
on PickupDatetimePScheme(pickup_datetime)
go

-- Create a new index for the NYC Taxi trip fare table
-- Index is partitioned according to partition scheme
create index nyctaxi_fare_idx on nyctaxi_fare(medallion, hack_license, pickup_datetime)
on PickupDatetimePScheme(pickup_datetime)
go