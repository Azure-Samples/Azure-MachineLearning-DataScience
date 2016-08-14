source("sim_data.R")
source("learning_curve_lib.R")

N <- 500000
data_table <- sim_data(N, cardinality=8)
# rxSetComputeContext("local")
# N <- 1e6
# rxHadoopMakeDir("wasb:///sim_data")
# rxHadoopMakeDir("wasb:///sim_data/1M10sd130t")
# data_table <- RxXdfData("wasb:///sim_data/1M10sd130t", fileSystem=RxHdfsFileSystem())
# sim_big_data(data_table, N/1e5, rows_per_chunk=1e5, cardinality=10)

K_FOLDS <- 8
SALT <- 1
NUM_TSS <- 8
formulas <- sapply(2:8, function(i) (create_formula("y2", paste0("x", 1:i), interaction_pow=2)))
formulas <- c(formulas, "y2 ~ x1:x2 + x3:x4 + x5:x6 + x7:x8")
MAX_TSS <- (1 - 1/K_FOLDS) * N # approximate number of cases available for training.
training_fractions <- get_training_set_fractions(5000, MAX_TSS, NUM_TSS)

grid_dimensions <- list( model_class="rxLinMod",
                         training_fraction=training_fractions,
                         with_formula=formulas,
                         test_set_kfold_id=1,
                         KFOLDS=K_FOLDS)

parameter_table <- do.call(expand.grid, c(grid_dimensions, stringsAsFactors=FALSE))
parameter_list <- lapply(1:nrow(parameter_table), function(i) parameter_table[i,])

# rxSetComputeContext("localpar")
rxSetComputeContext(RxSpark(consoleOutput=TRUE))
training_results <- rxExec(run_training_fraction,
                           elemArgs = parameter_list,
                           execObjects = c("data_table", "SALT"))
training_results_df <- do.call("rbind", training_results)

library(ggplot2)
library(dplyr)

# pdf("demo_figures.pdf", width=10.5, height=7)
training_results_df %>%
  ggplot(aes(x=log10(tss), y=test, col=formula)) +
  geom_line(size=1.2) + geom_point() + 
  ylab("test RMSE") + coord_cartesian(ylim=c(10,11)) +
  ggtitle("Simulated data with input cardinality 8")
# dev.off()

