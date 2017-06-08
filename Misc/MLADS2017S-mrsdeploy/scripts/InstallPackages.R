install.packages("broom", repos='http://cran.us.r-project.org')
install.packages("AzureML", repos='http://cran.us.r-project.org')
install.packages("ggplot2", repos='http://cran.us.r-project.org')

install.packages("devtools",repos='http://cran.us.r-project.org')
library(devtools)
install_github(c("Azure/rAzureBatch", "Azure/doAzureParallel"))
