## Download scripts and code files into directories
cd /home/remoteuser
mkdir Code  
mkdir Code/MRS Code/sparklyr

cd /home/remoteuser
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/downloadRun.sh
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/github_installs.R
chmod +x downloadRun.sh

cd  /home/remoteuser/Code/sparklyr
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparklyR_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparklyR_NYCTaxi.html

## Install packages, remove older version of packages prior to installation
cd /home/remoteuser
sudo apt-get -y -qq install libcurl4-openssl-dev

cd /usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library
if [[ -d sparklyr ]]; then sudo rm -Rf sparklyr; fi;
if [[ -d sparkapi ]]; then sudo rm -Rf sparkapi; fi;
if [[ -d rprojroot ]]; then sudo rm -Rf rprojroot; fi;
if [[ -d dplyr ]]; then sudo rm -Rf dplyr; fi;
if [[ -d Rcpp ]]; then sudo rm -Rf Rcpp; fi;
if [[ -d DBI ]]; then sudo rm -Rf DBI; fi;
if [[ -d config ]]; then sudo rm -Rf config; fi;
if [[ -d tibble ]]; then sudo rm -Rf tibble; fi;
if [[ -d devtools ]]; then sudo rm -Rf devtools; fi;
if [[ -d rmarkdown ]]; then sudo rm -Rf rmarkdown; fi;
if [[ -d knitr ]]; then sudo rm -Rf knitr; fi;

cd /home/remoteuser/R/x86_64-pc-linux-gnu-library/3.2
if [[ -d rmarkdown ]]; then sudo rm -Rf rmarkdown; fi;

# Call R file to install packages
sudo R --vanilla --quiet  <  /home/remoteuser/Scripts/github_installs.R

## Set working directory
cd /home/remoteuser/Code
