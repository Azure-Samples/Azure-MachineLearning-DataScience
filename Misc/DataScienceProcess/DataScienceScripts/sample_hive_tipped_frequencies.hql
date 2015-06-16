SELECT tipped, COUNT(*) AS tip_freq 
FROM 
(
    SELECT if(tip_amount > 0, 1, 0) as tipped, tip_amount
    FROM nyctaxidb.fare
)tc
GROUP BY tipped;