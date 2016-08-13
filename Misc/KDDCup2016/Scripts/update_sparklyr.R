.libPaths("/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library")
setwd("/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library")

remove.packages("sparklyr")
install.packages("/home/remoteuser/sparklyr0801.tar.gz", repos=NULL, type="source")