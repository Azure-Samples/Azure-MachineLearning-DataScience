# ## Hierarchical time series
#   
#   Time series data can often be disaggregated by attributes of interest to form groups of time series or a hierarchy. For example, one might be interested in forecasting demand of all products in total, by location, by product category, by customer, etc. (see picture below). Forecasting hierarchical time series data is challenging because the generated forecasts need to satisfy the aggregate requirement, that is, lower-level forecasts need to sum up to the higher-level forecasts. There are many approaches that solve this problem, differing in the way they aggregate individual time series forecasts across the groups or the hierarchy: bottom-up, top-down, or middle-out.
# 
# Training hierarchical time series forecasting models require searching through a large parameter space. The model's performance greatly varies over the parameters we choose, some of which are: 
# 
# * univariate time series method for individual series prediction
# * method for reconciling forecasts across hierarchy
# * weights we use to reconcile forecasts across hierarchy
# * etc.
# 
# 
# In this tutorial, we will use Australian tourism data set from 'fpp' package as a sample data set. 
# 
# Rob J Hyndman (2013). fpp: Data for "Forecasting: principles and practice". R package version 0.5.
# https://CRAN.R-project.org/package=fpp
# 
# This data set contains quarterly visitor nights spent by international tourists to Australia available for years 1999-2010. We will use this historical data to forecast nights spent by tourists in Australia:
# 
# * In total
# * By state
# * By city
# 
# This data can be represented as a hierarchy, as shown in the following picture:
# 
# ![Australia tourism data set](./aust_hierarchy.png)
# 
# ## Outline
# In this tutorial we will:
# 
# 1. create a hierarchical time series
# 2. split the data into training and testing
# 3. generate a grid of input parameters for forecasting function
# 4. call rxExec() to run forecasting over the parameter space distributed
# accross local cores or cluster nodes
# 5. find optimal parameters based on all runs
# 6. forecast the next two years using the optimal parameters
# 7. try running the above for larger data size
# 
# 
# ## HTS Forecasting
# 
# ### Loading necessary libraries

# Setting the environment
if(Sys.getenv("SPARK_HOME")==""){
  Sys.setenv(SPARK_HOME="/dsvm/tools/spark/current")
}

Sys.setenv(YARN_CONF_DIR="/opt/hadoop/current/etc/hadoop", 
           JAVA_HOME = "/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.111-1.b15.el7_2.x86_64")
Sys.setenv(PATH="/anaconda/envs/py35/bin:/dsvm/tools/cntk/cntk/bin:/usr/local/mpi/bin:/dsvm/tools/spark/current/bin:/anaconda/envs/py35/bin:/dsvm/tools/cntk/cntk/bin:/usr/local/mpi/bin:/dsvm/tools/spark/current/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/opt/hadoop/current/sbin:/opt/hadoop/current/bin:/home/remoteuser/.local/bin:/home/remoteuser/bin:/opt/hadoop/current/sbin:/opt/hadoop/current/bin")

# Loading libraries
if(!require("hts")) install.packages('hts')
if(!require("fpp")) install.packages('fpp')

library(hts)
library(fpp)

### Forecasting function
# 
# We will use the following function for time series forecasting. The function runs hierarchical forecast on training data set
# and returns evaluation metrics on test data set


forecast_hts <- function (traindata, testdata, htsmethod, tsmethod, combweights){
  
  # Forecasting horizon
  horiz =  dim(aggts(testdata))[1]
  
  # Run hierarchical forecast
  hts_fcast <- forecast(object  = traindata, 
                        h       = horiz,
                        method  = htsmethod,
                        fmethod = tsmethod,
                        weights = combweights)
  
  # Return evaluation metrics at the top level
  fcast_acc <- accuracy.gts(hts_fcast, test = testdata, levels = 0)
  
}


### Hierarchical time series data set
# 
# Let's process the data

# Create hierachical time series dataset
htsdata <- hts(vn, nodes=list(4,c(2,2,2,2)))

# Rename the nodes of the hierarchy
htsdata$labels$`Level 1` <- c("NSW", "VIC", "QLD", "Other")
htsdata$labels$`Level 2` <- c("Sydney", "NSW-Other", "Melbourne", "VIC-Other", "BrisbaneGC", "QLD-Other", "Capitals", "Other")
names(htsdata$labels) <- c("Total", "State", "City")

# Let's look at the data
htsdata

# Split data into train and test (leave out years 2010 and 2011 for testing)
train_data <- window(htsdata,  end = c(2009, 4))
test_data <- window(htsdata, start = c(2010, 1))


### Visualizing hierarchy
# 
# Let's see what the hierarchical time series data looks like.

# Plot the hierarchial time series data
plot(htsdata)


### Parameter space
#
# Let's generate the parameter space

# Vary methods for generating base time series forecasts
ts_method <- c("ets", "arima", "rw")

# Vary methods for reconciling base forecasts to satisfy aggregation requirement
hts_method <- c("bu", "comb", "tdgsa", "tdgsf", "tdfp") 

# Vary forecast weights for the optimal cobination approach 
comb_weights <- c("mint", "wls", "ols", "nseries")

# Generate all possible combinations of the above parameters
param_space <- expand.grid(hts_method, ts_method, comb_weights, stringsAsFactors = FALSE)
colnames(param_space) <- c("hts_method", "ts_method", "comb_weights")


# Remove ilegal combinations
#   - comb_weights only applies to hts_method == "comb"
rm_inds <- param_space$hts_method != "comb"
param_space$comb_weights[rm_inds] <- "none"
param_space <- param_space[!duplicated.data.frame(param_space),]


### Compute contexts
# 
# Using Microsoft R Server's _rxSetComputeContext()_ function we can easily switch between different compute platforms, 
# and run the same piece of code on those different platforms. _rxExec()_ function then distributes the execution of
# the forecasting function we defined above onto the specified compute context.
# 
# * rxSetComputeContext("local") - sets compute context to "local" and causes rxExec() 
# to execute runs locally in a serial manner.
# 
# * rxSetComputeContext(RxLocalParallel()) - causes rxExec() to run multiple tasks 
# in parallel, thereby using the multiple cores on your local machine. 
# The downside is that this will use more memory and will slow down your computer 
# for other work you may be trying to do at the same time.
# 
# * rxSetComputeContext(RxSpark()) - for parallelized distributed execution via Spark 
# across the nodes of a cluster

rxSetComputeContext(RxLocalParallel())
# rxSetComputeContext(RxSpark(consoleOutput=TRUE, numExecutors = 1, executorCores=2, executorMem="1g"))

# Measure execution time
et <- system.time(
  
  # Run many distributed jobs
  rxResult <- rxExec(FUN            = forecast_hts,  
                     traindata      = train_data, 
                     testdata       = test_data, 
                     htsmethod      = rxElemArg(param_space$hts_method),  
                     tsmethod       = rxElemArg(param_space$ts_method),
                     combweights    = rxElemArg(param_space$comb_weights),
                     consoleOutput  = TRUE,
                     packagesToLoad = c('hts'))
)

cat(paste("Elapsed time: ", format(et['elapsed'], digits = 4), "seconds. \n"))


### Gather the results
# Collect the results of the rxExec(), and find the result with the best evaluation metric (smallest MAPE)

all_mape <- sapply( rxResult, function(x) x["MAPE",] )
min_mape_indx <- which.min(all_mape)

# Optimal parameters
opt_params <- param_space[min_mape_indx,]

# Forecast the next 8 quarters using optimal parameters
horiz <- 8
hts_fcast <- forecast(object  = htsdata, 
                      h       = horiz,
                      method  = opt_params$hts_method,
                      fmethod = opt_params$ts_method)


### Print out the optimal results

output <- paste("OPTIMAL RESULTS \n\n",
                "Minimum obtained MAPE: ", format(min(all_mape), digits = 4), "\n",
                "Optimal method for distributing forecasts within the hierarchy: ", opt_params$hts_method, "\n",
                "Optimal forecasting method: ", opt_params$ts_method, "\n")
cat(output)

if(opt_params$hts_method == "comb") cat(paste("Optimal weights used for `comb` method: ", opt_params$comb_weights, "\n"))

cat("\n Forecast for the next two years at the City level obtained using optimal parameters: \n\n")

print(aggts(hts_fcast, levels = 2))

# Plot the forecasted time series
names(hts_fcast$labels) <- c("Total", "State", "City")
plot(hts_fcast)

## Hands-on exercise
# 
# In this part, we will try to run the above parameter sweep on a larger data set. Forecasting hierarchical time series takes more time for deeper and wider hierarchies, which are very common in real life applications. For example, if we were to forecast company sales by state, city, store, product category, and product, we would end up with hundreds of thousands of time series. Forecasting this time series hierarchy for just one parameter set may take hours. Doing a parameter sweep in such a scenario would be prohibitive. Being able to distribute that computation to a Spark cluster (by switching to _RxSpark()_ compute context) with hundreds of cores reduces that time drastically.
# 
# Here, we will generate a larger time series data set. We will do that by replicating the existing data set, and adding a little bit of noise to it. To increase the data set we will multiply the number of time series with a factor _x_.

### Generating larger data


# Increase the number of time series by factor x
# TRY changing this variable
x = 2

# Function to add noise to a data set
addNoise <- function(data) {
  
  data_dim <- dim(data)[1] * dim(data)[2]
  noise <- matrix(runif(data_dim, -500, 500), dim(data)[1])
  noisified <- data + noise
  return(noisified)
  
}

# Replicate time series x times
larger_data <- coredata(vn)[ ,  rep(seq(ncol(vn)), x)]
larger_data <- addNoise(larger_data)

# Create time series object
vnx <- ts(larger_data, frequency = 4, start = c(1998, 1))

# Create hierachical time series dataset
htsdata <- hts(vnx, nodes=list(4*x, rep(c(2,2,2,2), x)))

# Let's see what our data looks like
print(htsdata)

# Rename the nodes of the hierarchy
htsdata$labels$`Level 1` <- paste0('State_', 1:length(htsdata$labels$`Level 1`))
htsdata$labels$`Level 2` <- paste0('City_', 1:length(htsdata$labels$`Level 2`))
names(htsdata$labels) <- c("Total", "State", "City")

# Split data into train and test (leave out years 2010 and 2011 for testing)
train_data <- window(htsdata,  end = c(2009, 4))
test_data <- window(htsdata, start = c(2010, 1))


# TRY changing the compute context and see how it affects the execution time
rxSetComputeContext(RxLocalParallel())
# rxSetComputeContext(RxSpark(consoleOutput=TRUE, numExecutors = 1, executorCores=2, executorMem="1g"))

# Measure execution time
et <- system.time(
  
  # Run many distributed jobs
  rxResult <- rxExec(FUN            = forecast_hts,  
                     traindata      = train_data, 
                     testdata       = test_data, 
                     htsmethod      = rxElemArg(param_space$hts_method),  
                     tsmethod       = rxElemArg(param_space$ts_method),
                     combweights    = rxElemArg(param_space$comb_weights),
                     consoleOutput  = TRUE,
                     packagesToLoad = c('hts'))
)

cat(paste("Elapsed time: ", format(et['elapsed'], digits = 4), "seconds. \n"))

all_mape <- sapply( rxResult, function(x) x["MAPE",] )
min_mape_indx <- which.min(all_mape)

# Optimal parameters
opt_params <- param_space[min_mape_indx,]

# Forecast the next 8 quarters using optimal parameters
horiz <- 8
hts_fcast <- forecast(object  = htsdata, 
                      h       = horiz,
                      method  = opt_params$hts_method,
                      fmethod = opt_params$ts_method)

plot(hts_fcast)
