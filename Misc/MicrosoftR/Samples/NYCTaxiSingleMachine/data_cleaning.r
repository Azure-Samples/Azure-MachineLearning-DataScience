# convert csv files to xdf format in parallel
##############################################

# create xdf files from a list of ids of csv files
create_xdf <- function (i) 
{  
    # create xdf file for each one of the input ids
    if (length(i) > 1L)
        return(sapply(i, create_xdf))
       
    # location of input and output
    raw_data_path <- ".\\RawData"
    xdf_files <- ".\\xdf"
    
    # definitions of months and taxis to be included in the dataset   
    months <- 1:12 
    years <- 2010:2013
    colors <- c("yellow")
    all_months <- expand.grid(year = years, month = months, color = colors)
    
    # create input file name    
    month <- all_months$month[i]
    month0 <- sprintf("%02d", month)
    year <- all_months$year[i]
    color <- all_months$color[i]
    filename <- paste(color, "_tripdata_", year, "-", month0, sep = "")
    infile <- file.path(raw_data_path, paste(filename, ".csv", sep = ""))

    # create file name of intermediate and the final xdf files
    xdf_file <- file.path(xdf_files, paste(filename, ".xdf", sep = ""))
    dataset_file <- file.path(xdf_files, paste(filename, "_features.xdf", sep = ""))

    # re-code rate_code categorical column    
    colInfoList <- list("rate_code" = list(type = "factor", 
                        levels = c("1", "2", "3", "4", "5", "6"),
                        newLevels = c("Standard rate", "JFK", "Newark",
                                      "Nassau or Westchester",
                                      "Negotiated fare", "Group ride")))
    
    # types of all input columns
    colClasses = c(vendor_id = "character", pickup_datetime = "character",
                   dropoff_datetime = "character", passenger_count = "uint16",
                   trip_distance = "numeric", pickup_longitude = "numeric",
                   pickup_latitude = "numeric", rate_code = "factor",
                   store_and_fwd_flag = "factor”, dropoff_longitude = "numeric",
                   dropoff_latitude = "numeric", payment_type = "factor",
                   fare_amount = "numeric", surcharge = "numeric",
                   mta_tax = "numeric", tip_amount = "numeric",
                   tolls_amount = "numeric", total_amount = "numeric")

    # all possible values of payment_type field, when the payment is by cash or by credit    
    credit_ids <- c(”CRE”, ”Cre”, ”CRD”, ”CARD”)
    cash_ids <- c(”CAS”, ”Cas”, ”CSH”, ”CASH”)     

    # convert from csv to intermediate xdf file
    data <- rxImport(inData = infile, outFile = xdf_file, overwrite = TRUE, 
                     colInfo = colInfoList, colClasses = colClasses,
                     
                     # parse several variables in the right way, create label and new features
                     transforms = list(pickup_datetime = as.POSIXct(pickup_datetime, format = "%Y-%m-%d %H:%M:%S", tz = "America/New_York"),
                                       dropoff_datetime = as.POSIXct(dropoff_datetime, format = "%Y-%m-%d %H:%M:%S", tz = "America/New_York"),
                                       duration = as.numeric(dropoff_datetime - pickup_datetime, units="mins"),
                                       weekday = weekdays(pickup_datetime),
                                       hour = (as.POSIXlt(pickup_datetime))$hour,
                                       label = ifelse(tip_amount > 0, 1, 0),
                                       payment_type = ifelse(payment_type %in% credit_ids, "Credit Card",
                                                             ifelse(payment_type %in% cash_ids, "Cash", "Void"))),

                     # remove all rows that apparently have garbage values
                     rowSelection = (payment_type == "Credit Card" | payment_type == "Cash") & 
                                    passenger_count > 0 & surcharge >= 0 &  
                                    tolls_amount >= 0 & tip_amount >= 0 &  
                                    trip_distance < 1000 & trip_distance > 0 & 
                                    fare_amount > 0 & mta_tax >= 0 & 
                                    pickup_latitude > 35 & pickup_latitude < 45 & 
                                    dropoff_latitude > 35 & dropoff_latitude < 45 & 
                                    pickup_longitude > -79 & pickup_longitude < -68 & 
                                    dropoff_longitude > -79 & dropoff_longitude < -68 & duration > 0,

                     # remove unnecessary columns
                     varsToDrop = c("vendor_id", "store_and_fwd_flag", "total_amount"))

    # create factors from two new columns
    factors <- list(weekday=list(levels=c("Sunday","Monday","Tuesday",                   
                                          "Wednesday","Thursday","Friday","Saturday")),
                    payment_type = list(levels = c("Credit Card","Cash")))
    dataset <- rxFactors(inData = xdf_file, outFile = dataset_file, 
                         factorInfo = factors, overwrite = TRUE)

    # remove intermediate file
    file.remove(xdf_file)
}

# create parallel compute context
rxSetComputeContext(RxLocalParallel())
rxOptions(numCoresToUse = 8)

# split processing between 8 cores, each core will process 6 files
rxExec(create_xdf, i = rxElemArg(1:48), taskChunkSize = 6)
