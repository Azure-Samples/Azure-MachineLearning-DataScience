# download 4 year of NYC taxi rides
# the downloaded data is placed in RawData directory
####################################################

library(httr)

# definitions of months and taxis to be included in the dataset
months <- 1:12
years <- 2010:2013
colors <- c("yellow")

# data frame with all combinations of year, month and taxi color to be downloaded 
all_months <- expand.grid(year = years, month = months, color = colors)

# prefix of URL of the dataset
prefix_name <- "https://storage.googleapis.com/tlc-trip-data/"

# the downloaded data is placed in RawData directory
if (!file.exists("RawData")) {
	dir.create("RawData")
}

# download a single file
download_file <- function (i) {

        # create name and URL of the i-th file to be downloaded 
	month <- all_months$month[i]
	month0 <- sprintf("%02d", month)
	year <- all_months$year[i]
	color <- all_months$color[i]
	filename <- paste(color, "_tripdata_", year, "-", month0, ".csv", sep="")
        destination <- paste("RawData\\", filename, sep="")
	full_url <- paste(prefix_name, year, "/", filename, sep="")	

        # download the file
	GET(full_url, write_disk(destination))
}

# go over all file names, download each one of them
sapply(1:nrow(all_months), download_file)
