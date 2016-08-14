.libPaths("/usr/lib64/microsoft-r/8.0/lib64/R/library")
setwd("/usr/lib64/microsoft-r/8.0/lib64/R/library")

remove.packages("sparklyr")
install.packages("/home/remoteuser/sparklyr0801.tar.gz", repos=NULL, type="source")
