cd 
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/sparklyRInstall.sh
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/github_installs.R

mkdir Code  
mkdir Code/MRS Code/sparklyr

cd  Code/sparklyr
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparklyR_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparklyR_NYCTaxi.html


cd 
sudo apt-get install libcurl4-openssl-dev

cd /usr/lib64/MRO-for-MRS-8.0.3/R-3.2.2/lib/R/library
sudo rm -r sparklyr sparkapi rprojroot dplyr Rcpp DBI config tibble devtools rmarkdown

cd /home/remoteuser/R/x86_64-pc-linux-gnu-library/3.2
sudo rm -r rmarkdown

sudo R --vanilla --quiet  <  /home/remoteuser/Scripts/github_installs.R

cd
