# Learning curves on big data using Microsoft R Server

* `learning_curve_lib.R` defines the `run_training_fraction` function and some helper functions.
* `sim_data.R` has functions for generating the simulated data used in the demo.
* `rxLinMod_df.R` runs a simplified (low cardinality) example on a small dataframe.
* `rxLinMod_y2_xdf.R` runs learning curves for a family of formulas on a 10 million row simulated dataset in HDFS on the RxSpark compute context.
