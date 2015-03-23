SELECT COUNT(*) FROM nyctaxidb.trip
WHERE month=1
AND  (CAST(pickup_longitude AS float) NOT BETWEEN -90 AND 90
      OR CAST(pickup_latitude AS float) NOT BETWEEN -90 AND 90
      OR CAST(dropoff_longitude AS float) NOT BETWEEN -90 AND 90
      OR CAST(dropoff_latitude AS float) NOT BETWEEN -90 AND 90
      OR (pickup_longitude = '0' AND pickup_latitude = '0')
      OR (dropoff_longitude = '0' AND dropoff_latitude = '0'));