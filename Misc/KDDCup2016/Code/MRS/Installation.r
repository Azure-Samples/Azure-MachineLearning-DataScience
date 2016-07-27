# On HDI edge node, need to run this so that the AzureML package can be installed:
# sudo apt-get -y update && sudo apt-get -y install libcurl4-gnutls-dev
# sudo apt-get -y install libssl-dev
# sudo apt-get -y install libxml2-dev

# Run R using "sudo" if you want to install AzureML system-wide

options("repos"="https://mran.revolutionanalytics.com")

if(!require("AzureML")) install.packages("AzureML")

library(AzureML)
