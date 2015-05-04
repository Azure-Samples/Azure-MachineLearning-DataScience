SELECT CAST(hist.x as int) as bin_center, CAST(hist.y as bigint) as bin_height FROM 
        (SELECT
        histogram_numeric(col2, 20) as col2_hist
        FROM
        criteo.criteo_train
        ) a
        LATERAL VIEW explode(col2_hist) exploded_table as hist;