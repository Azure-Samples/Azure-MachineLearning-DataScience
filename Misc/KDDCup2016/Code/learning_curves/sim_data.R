# sim_data
# Generate simulated data for learning curve examples.
# This version runs on open source R
# @example write.csv(sim_data(1e6), "sim_data100M.csv", row.names=FALSE)
sim_data <- function(N, noise=10, threshold=130, cardinality=10){
  library(dplyr)
  categories <- LETTERS[1:cardinality]
  d <- data.frame(
    x1 = sample(categories, N, replace=TRUE),
    x2 = sample(categories, N, replace=TRUE),
    x3 = sample(categories, N, replace=TRUE),
    x4 = sample(categories, N, replace=TRUE),
    x5 = sample(categories, N, replace=TRUE),
    x6 = sample(categories, N, replace=TRUE),
    x7 = sample(categories, N, replace=TRUE),
    x8 = sample(categories, N, replace=TRUE)
  )
  mutate(d, 
            y1=100 + ifelse(x1==x2, 10, 0) + rnorm(N, sd=noise),
            y2=100 + 
              ifelse(x1==x2, 16, 0) + 
              ifelse(x3==x4, 8, 0) +
              ifelse(x5==x6, 4, 0) +
              ifelse(x7==x8, 2, 0) +
              rnorm(N, sd=noise),
            bad_widget = y2 > threshold
          )
}

# @example
#   source("sim_data.R")
#   rxHadoopMakeDir("wasb:///sim_data/100M10sd130t")
#   sim_data_xdf <- RxXdfData("wasb:///sim_data/100M10sd130t", fileSystem=RxHdfsFileSystem())
#   sim_big_data(sim_data_xdf, 1000, seed=1)
sim_big_data <- function(sim_data_xdf, num_chunks, rows_per_chunk=100000, 
                         noise=10, threshold=130, cardinality=10, seed=1){

  sim_X <- function(N, num_inputs=8, numCategories){
    library(parallel)
    num_cores <- if ("Windows" == Sys.info()[['sysname']]) 1
      else min(num_inputs, detectCores(logical=FALSE))
    random_categorical <- function(N){ 
      factor(sample(LETTERS[1:numCategories], N, replace=TRUE), 
             levels=LETTERS[1:numCategories])
    }
    vars <- rep(N, num_inputs)
    names(vars) <- paste0("x", 1:num_inputs)
    as.data.frame( mclapply(vars, random_categorical, mc.cores=num_cores) )
  }
  
  set.seed(seed)
  for (i in 1:num_chunks){
    print(paste("block", i))
    df <- sim_X(N=rows_per_chunk, numCategories=cardinality)
    rxDataStep(df, sim_data_xdf, 
              transforms=list(
                y1=100 + ifelse(x1==x2, 10, 0) + rnorm(.rxNumRows, sd=noise),
                y2=100 + ifelse(x1==x2, 16, 0) + 
                  ifelse(x3==x4, 8, 0) +
                  ifelse(x5==x6, 4, 0) +
                  ifelse(x7==x8, 2, 0) +
                  rnorm(.rxNumRows, sd=noise),
                bad_widget=y2>threshold
              ),
              append=if(i==1)"none" else "rows", 
              overwrite=(i==1),
              transformVars=paste0('x', 1:8),
              transformObjects=list(noise=noise, threshold=threshold)
    )
  }
}