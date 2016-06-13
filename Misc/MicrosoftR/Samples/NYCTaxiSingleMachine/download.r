library(httr)

months <- 1:12
years <- 2010:2013
colors <- c("yellow","green")
all_months_init <- expand.grid(year=years,month=months,color=colors)
prefix_name <- "https://storage.googleapis.com/tlc-trip-data/"
if (!file.exists("RawData")) {
	dir.create("RawData")
}

download_file <- function (i) {
	month <- all_months$month[i]
	month0 <- sprintf("%02d",month)
	year <- all_months$year[i]
	color <- all_months$color[i]
	filename <- paste(color,"_tripdata_",year,"-",month0,".csv",sep="")
	full_url <- paste(prefix_name,year,"/",filename,sep="")
	destination <- paste("RawData\\", filename, sep="")
	GET(full_url,write_disk(destination))
}

sapply(1:nrow(all_months),download_file)
