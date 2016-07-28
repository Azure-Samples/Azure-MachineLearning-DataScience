## Download scripts and code files into directories
cd 
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/downloadRun.sh
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/github_installs.R
chmod +x downloadRun.sh

mkdir Code  
mkdir Code/MRS Code/sparklyr

cd  Code/sparklyr
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparklyR_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparklyR_NYCTaxi.html


## Install packages, remove older version of packages prior to installation
cd 
sudo apt-get install libcurl4-openssl-dev

cd /usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library
sudo rm -r sparklyr sparkapi rprojroot dplyr Rcpp DBI config tibble devtools rmarkdown

cd /home/remoteuser/R/x86_64-pc-linux-gnu-library/3.2
sudo rm -r rmarkdown

sudo R --vanilla --quiet  <  /home/remoteuser/Scripts/github_installs.R

## Set working directory
cd /home/remoteuser/Code
