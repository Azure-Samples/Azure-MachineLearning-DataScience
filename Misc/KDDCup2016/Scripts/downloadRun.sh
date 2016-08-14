amlToken=$1

###########################################################################
## Download scripts and code files into directories
###########################################################################
cd /home/remoteuser
if [[ -f github_installs.R ]]; then sudo rm -Rf github_installs*; fi;
if [[ -f downloadRun.sh ]]; then sudo rm -Rf downloadRun*; fi;
if [[ -d Code ]]; then sudo rm -Rf Code; fi;
mkdir Code  
mkdir Code/MRS Code/SparkR Code/UseCaseHTS Code/learning_curves

cd /home/remoteuser

wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/downloadRun.sh
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/github_installs.R
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/update_sparklyr.R
chmod +x downloadRun.sh
chmod +x downloadRun_sparklyr.sh

cd  /home/remoteuser/Code/SparkR
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparkR_sparklyr_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/SparkR_sparklyr_NYCTaxi.html
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/sparklyr_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/sparklyr_NYCTaxi.R
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/SparkR/sparklyr_NYCTaxi.html

cd  /home/remoteuser/Code/UseCaseHTS
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/UseCaseHTS/sample_demo.R

cd  /home/remoteuser/Code/MRS
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/1-Clean-Join-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/2-Train-Test-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/3-Deploy-Score-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/Installation.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/SetComputeContext.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/azureml-settings.json
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/MRS/dTreeModelSubset.RData

cd  /home/remoteuser/Code/learning_curves
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/learning_curves/README.md
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/learning_curves/learning_curve_lib.R
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/learning_curves/run_learning_curve_demo.R
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Code/learning_curves/sim_data.R

###########################################################################
## Store the AML token in azureml-settings.json
###########################################################################

sudo sed -i.bak "s/replaceWithToken/$amlToken/" /home/remoteuser/Code/MRS/azureml-settings.json

###########################################################################
## Reduce spark logging, because it slows down RStudio
###########################################################################

sudo sed -i.bak 's/INFO/WARN/' /etc/spark/2.4.2.4-5/0/log4j.properties

###########################################################################
## Install packages, remove older version of packages prior to installation
###########################################################################
cd /home/remoteuser

# the tibble package now seems to require /bin/gtar
sudo ln -s /bin/tar /bin/gtar

sudo apt-get -y -qq install libcurl4-openssl-dev
sudo apt-get -y -qq install libcurl4-gnutls-dev
sudo apt-get -y -qq install libssl-dev
sudo apt-get -y -qq install libxml2-dev

cd /usr/lib64/microsoft-r/8.0/lib64/R/library
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
if [[ -d AzureML ]]; then sudo rm -Rf AzureML; fi;
if [[ -d RCurl ]]; then sudo rm -Rf RCurl; fi;
if [[ -d rjson ]]; then sudo rm -Rf rjson; fi;
if [[ -d hts ]]; then sudo rm -Rf hts; fi;
if [[ -d fpp ]]; then sudo rm -Rf fpp; fi;
if [[ -d randomForest ]]; then sudo rm -Rf randomForest; fi;

cd /home/remoteuser/R/x86_64-pc-linux-gnu-library/3.2
if [[ -d rmarkdown ]]; then sudo rm -Rf rmarkdown; fi;

# Call R file to install packages
cd /home/remoteuser
sudo R --vanilla --quiet  <  /home/remoteuser/github_installs.R

# update sparklyr to version 0.2.32
wget https://github.com/rstudio/sparklyr/archive/df9de9a5c52a89ae025483652d2c033162f185cd.zip -O sparklyr0801.zip
unzip sparklyr0801.zip
tar -czvf sparklyr0801.tar.gz sparklyr-df9de9a5c52a89ae025483652d2c033162f185cd

sudo R --vanilla --quiet  <  /home/remoteuser/update_sparklyr.R
###########################################################################
## Change permission of Code directory
###########################################################################
sudo chmod -R 777 /home/remoteuser/Code

###########################################################################
## Set final working directory
###########################################################################
cd /home/remoteuser/Code
