.libPaths("/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R")

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
devtools::install_github("rstudio/rmarkdown");
install.packages("ggplot2", repos='http://cran.us.r-project.org')
install.packages("gridExtra", repos='http://cran.us.r-project.org')

.libPaths("/home/remoteuser/R/x86_64-pc-linux-gnu-library/3.2")
devtools::install_github("rstudio/rmarkdown");

.libPaths("/usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library")
devtools::install_github("rstudio/rmarkdown");
