SELECT COUNT(*) FROM nyctaxidb.trip
WHERE month=1
AND  (CAST(pickup_longitude AS float) NOT BETWEEN -90 AND -30
      OR CAST(pickup_latitude AS float) NOT BETWEEN 30 AND 90
      OR CAST(dropoff_longitude AS float) NOT BETWEEN -90 AND -30
      OR CAST(dropoff_latitude AS float) NOT BETWEEN 30 AND 90);