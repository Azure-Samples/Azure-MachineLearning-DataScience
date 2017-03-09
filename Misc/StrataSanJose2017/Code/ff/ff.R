# 
# DESCRIPTION
# 
# This script shows an example of how to create and use ffdf objects
# with the "ff" and its related packages.
#

# install "ff" and related packages:
if(!require("ff")) install.packages('ff')
if(!require("ffbase")) install.packages('ffbase')
if(!require("biglm")) install.packages('biglm')


##### Example of "ff"

# change working directory
setwd("/home/remoteuser/Data")

# call the library
library("ff")

# read airline data into a ffdf object (20 million rows * 26 columns; 1.5GB)
# (it takes 2+ mins~)
airline_ff <- read.csv.ffdf(file = "airline_20MM.csv",
                            header = TRUE,
                            na.strings = NA)
head(airline_ff)

# size of ffdf object in memory = 87960 bytes/88 KB
object.size(airline_ff)


##### Example of "ffbase"

# call the library
library("ffbase")
library("biglm")

# perform simply data transformation on "CRSDepTime"
# round "CRSDepTime" to the nearest hour
airline_ff[, "CRSDepTime"] <- floor(airline_ff[, "CRSDepTime"] / 100)

# fit a glm model
# (it takes 2+ mins)
model_ff <- bigglm.ffdf(formula = IsArrDelayed ~ Month+DayofMonth+DayOfWeek+CRSDepTime+Distance, 
                        data = airline_ff, family = binomial())
summary(model_ff)
