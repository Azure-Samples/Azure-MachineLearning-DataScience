.libPaths("/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library")
setwd("/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library")

install.packages("devtools", repos='http://cran.us.r-project.org')
library(devtools)

options(unzip = 'internal')
devtools::install_github("hadley/tibble");
devtools::install_github("rstudio/config");
devtools::install_github("rstats-db/DBI");
install.packages("Rcpp", repos='http://cran.us.r-project.org')
devtools::install_github("hadley/dplyr");
devtools::install_github("krlmlr/rprojroot");
devtools::install_github("rstudio/sparklyr");
install.packages("rmarkdown", repos='http://cran.us.r-project.org')
install.packages("ggplot2", repos='http://cran.us.r-project.org')
install.packages("gridExtra", repos='http://cran.us.r-project.org')
