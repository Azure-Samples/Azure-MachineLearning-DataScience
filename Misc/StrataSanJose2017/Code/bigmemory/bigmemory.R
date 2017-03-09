setwd("~/airline")

library("bigmemory")
# Read airline data into a big matrix object (20 million rows * 26 columns)
backing.file    <- "airline_big.bin"
descriptor.file <- "airline_big.desc"
airline_big <- read.big.matrix("airline_20MM.csv", 
                               header = TRUE,
                               type = "integer",
                               sep = ",",
                               backingfile = backing.file,
                               descriptorfile = descriptor.file,
                               shared = TRUE)

# size of big matrix object = 664 bytes/0.6 KB
object.size(airline_big)
# size of R matrix object = 2080002048 bytes/2.08 GB
airline_matrix <- airline_big[,]
object.size(airline_matrix)


# comparing to read.csv()
system.time(airline_df <- read.csv("airline_20MM.csv", 
                                   header = TRUE,
                                   sep = ","))




# load big matrix from descriptor file
airline_big <- attach.big.matrix(descriptor.file)

# calculate the fraction of arrival delays = 46.92%
length(mwhich(airline_big, cols = 25, 
              vals = 1, comps = "eq"))/
  nrow(airline_big)


library("biganalytics")
# fit a kmeans model with 2 centers 
big_km <- bigkmeans(airline_big, centers = 2, 
                    iter.max = 10, nstart = 1, 
                    dist = "euclid")
