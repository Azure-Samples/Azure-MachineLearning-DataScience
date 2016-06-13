create_xdf <- function (i) 
{  
    if (length(i) > 1L)
        return(sapply(i,create_file))
       
    raw_data_path <- ".\\RawData"
    xdf_files <- ".\\xdf"
        
    months <- 1:12 
    years <- 2010:2013
    colors <- c("yellow")
    all_months <- expand.grid(year=years,month=months,color=colors)
        
    colInfoList <- list("rate_code" = list(type = "factor", 
                        levels = c("1","2","3","4","5","6"),
                        newLevels = c("Standard rate","JFK","Newark",
                                      "Nassau or Westchester",
                                      "Negotiated fare","Group ride")))
    
    colClasses = c(vendor_id="character",pickup_datetime="character",
                   dropoff_datetime="character",passenger_count="uint16",
                   trip_distance="numeric",pickup_longitude="numeric",
                   pickup_latitude="numeric",rate_code="factor",
                   store_and_fwd_flag="factor”,dropoff_longitude="numeric",
                   dropoff_latitude="numeric",payment_type="factor",
                   fare_amount="numeric",surcharge="numeric",
                   mta_tax="numeric",tip_amount="numeric",
                   tolls_amount="numeric",total_amount="numeric")
        
    weekdays = c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday",         
                 "Friday", "Saturday")
        
    month <- all_months$month[i]
    month0 <- sprintf("%02d",month)
    year <- all_months$year[i]
    color <- all_months$color[i]
    filename <- paste(color,"_tripdata_",year,"-",month0,sep="")
    
    infile <- file.path(raw_data_path,paste(filename,".csv",sep=""))
    xdf_file <- file.path(xdf_files,paste(filename,".xdf",sep=""))
    dataset_file <- file.path(xdf_files,
                              paste(filename,"_features.xdf",sep=""))
    
    credit_ids <- c(”CRE”,”Cre”,”CRD”,”CARD”)
    cash_ids <- c(”CAS”,”Cas”,”CSH”,”CASH”)     
    data <- rxImport(inData=infile,outFile=xdf_file,overwrite = TRUE 
              colInfo = colInfoList, colClasses = colClasses,
              transforms = list(                
                pickup_datetime = as.POSIXct(pickup_datetime, 
                                             format="%Y-%m-%d %H:%M:%S",
                                             tz="America/New_York"),
                dropoff_datetime = as.POSIXct(dropoff_datetime, 
                                              format="%Y-%m-%d %H:%M:%S",                        
                                              tz="America/New_York"),
                duration = as.numeric(dropoff_datetime - pickup_datetime, 
                                      units="mins"),
                weekday = weekdays(pickup_datetime),
                hour = (as.POSIXlt(pickup_datetime))$hour,
                label = ifelse(tip_amount > 0, 1, 0),
                payment_type = ifelse(payment_type %in% credit_ids, 
                                      "Credit Card",
                                       ifelse(payment_type %in% cash_ids, 
                                              "Cash", "Void"))),
              rowSelection = (payment_type == "Credit Card" | 
                              payment_type == "Cash") & 
                             passenger_count > 0 & surcharge >= 0 &  
                             tolls_amount >= 0 & tip_amount >= 0 &  
                             trip_distance < 1000 & trip_distance > 0 & 
                             fare_amount > 0 & mta_tax >= 0 & 
                             pickup_latitude > 35 & pickup_latitude < 45 & 
                             dropoff_latitude > 35 & dropoff_latitude < 45 & 
                             pickup_longitude > -79 & 
                             pickup_longitude < -68 & 
                             dropoff_longitude > -79 & 
                             dropoff_longitude < -68 & duration > 0,
              varsToDrop = c("vendor_id", "store_and_fwd_flag",                   
                             "total_amount"))

   # create factors from two new columns
   factors <- list(weekday=list(levels=c("Sunday","Monday","Tuesday",                   
                                "Wednesday","Thursday","Friday","Saturday")),
                   payment_type = list(levels = c("Credit Card","Cash")))
   dataset <- rxFactors(inData = xdf_file, outFile = dataset_file, 
                factorInfo = factors, overwrite = TRUE)
}

rxSetComputeContext(RxLocalParallel())
rxOptions(numCoresToUse=8)
rxExec(create_xdf,i=rxElemArg(1:48),taskChunkSize=6)
