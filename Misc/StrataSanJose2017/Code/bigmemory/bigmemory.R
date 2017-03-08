# 
# DESCRIPTION
# 
# This script shows an example of how to create and use big matrix objects
# with the "bigmemory" and its related packages.
#

# install "bigmemory" and related packages:
if(!require("bigmemory")) install.packages('bigmemory')
if(!require("biganalytics")) install.packages('biganalytics')


##### Example of "bigmemory"

# change working directory
setwd("/home/remoteuser/Data")

# call the library
library("bigmemory")

# read airline data into a big matrix object (20 million rows * 26 columns; 1.5GB)
# (it takes 1.5 mins~ ; depends on machine)
backing.file <- "airline_big.bin"
descriptor.file <- "airline_big.desc"
airline_big <- read.big.matrix("airline_20MM.csv", 
                               header = TRUE,
                               type = "integer",
                               sep = ",",
                               backingfile = backing.file,
                               descriptorfile = descriptor.file,
                               shared = TRUE)
head(airline_big)

# if descriptor.file is already exist, we can load the big matrix by attaching that file
# airline_big <- attach.big.matrix(descriptor.file)

# size of big matrix object = 664 bytes/0.6 KB
object.size(airline_big)

# convert big matrix object ot R matrix object
airline_matrix <- airline_big[,]

# size of R matrix object = 2080002048 bytes/2.08 GB
object.size(airline_matrix)

# read same data into R Data Frame (it takes 3 mins~; depends on machine)
airline_df <- read.csv("airline_20MM.csv", 
                       header = TRUE,
                       sep = ",")

# size of R Data Frame object = 2080003456 bytes/2.08 GB
object.size(airline_df)


##### Example of "biganalytics"

# call the library
library("biganalytics")

# perform simply data transformation on "CRSDepTime"
# round "CRSDepTime" to the nearest hour
airline_big[, "CRSDepTime"] <- floor(airline_big[, "CRSDepTime"] / 100)

# fit a glm model
model_big <- bigglm.big.matrix(formula = IsArrDelayed ~ Month+DayofMonth+DayOfWeek+CRSDepTime+Distance, 
                               data = airline_big, family = binomial())
summary(model_big)
