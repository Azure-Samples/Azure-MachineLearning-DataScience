#######################################################################################################################################
#######################################################################################################################################
## THIS SCRIPT CUSTOMIZES THE DSVM BY ADDING HADOOP AND YARN, INSTALLING R-PACKAGES, AND DOWNLOADING DATA-SETS FOR STRATA 
## SAN JOSE 2017 EXERCISES.
#######################################################################################################################################
#######################################################################################################################################


#######################################################################################################################################
## Start up several services, yarn, hadoop, rstudio server
#######################################################################################################################################
sudo systemctl start hadoop-namenode hadoop-datanode hadoop-yarn rstudio-server

#######################################################################################################################################
## MRS Deploy Setup
#######################################################################################################################################
cd 
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Scripts/backend_appsettings.json
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Scripts/webapi_appsettings.json

sudo mv backend_appsettings.json /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.BackEnd/appsettings.json
sudo mv webapi_appsettings.json /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.WebAPI/appsettings.json

sudo cp /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.WebAPI/autoStartScriptsLinux/*    /etc/systemd/system/.
sudo cp /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.BackEnd/autoStartScriptsLinux/*   /etc/systemd/system/.
sudo systemctl enable frontend
sudo systemctl enable rserve
sudo systemctl enable backend
sudo systemctl start frontend
sudo systemctl start rserve
sudo systemctl start backend

hadoop fs -mkdir /user/RevoShare/rserve2
hadoop fs -mkdir /user/RevoShare/rserve2/Predictions
hadoop fs -chmod -R 777 /user/RevoShare/rserve2

hadoop fs -mkdir /user/RevoShare/remoteuser
#######################################################################################################################################
# Copy data and code to VM
#######################################################################################################################################
mkdir  Data Code
mkdir Code/MRS Code/sparklyr Code/SparkR

## DOWNLOAD ALL CODE FILES
cd Code/MRS
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/1-Clean-Join-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/2-Train-Test-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/3-Deploy-Score-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/SetComputeContext.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/azureml-settings.json

cd
cd Code/sparklyr
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/sparklyr/SparkR_sparklyr_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/sparklyr/SparkR_sparklyr_NYCTaxi.html
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/sparklyr/sparklyr_NYCTaxi.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/sparklyr/sparklyr_NYCTaxi.html

## DOWNLOAD ALL DATA FILES
# NYC Taxi data
cd 
cd Data
wget http://cdspsparksamples.blob.core.windows.net/data/NYCTaxi/KDD2016/trip_fare_12.csv
wget http://cdspsparksamples.blob.core.windows.net/data/NYCTaxi/KDD2016/trip_data_12.csv
wget http://cdspsparksamples.blob.core.windows.net/data/NYCTaxi/KDD2016/JoinedParquetSampledFile.tar.gz
gunzip JoinedParquetSampledFile.tar.gz
tar -xvf JoinedParquetSampledFile.tar
mv JoinedParquetSampledFile NYCjoinedParquetSubset
rm JoinedParquetSampledFile.tar

# Airline data
wget http://cdspsparksamples.blob.core.windows.net/data/Airline/WeatherSubsetCsv.tar.gz
wget http://cdspsparksamples.blob.core.windows.net/data/Airline/AirlineSubsetCsv.tar.gz
gunzip WeatherSubsetCsv.tar.gz
gunzip AirlineSubsetCsv.tar.gz
tar -xvf WeatherSubsetCsv.tar
tar -xvf AirlineSubsetCsv.tar
rm WeatherSubsetCsv.tar AirlineSubsetCsv.tar

## Copy data to HDFS
cd
cd Data
hadoop fs -mkdir /user/RevoShare/remoteuser/Data
hadoop fs -copyFromLocal * /user/RevoShare/remoteuser/Data
#######################################################################################################################################
#######################################################################################################################################
# Install R packages
cd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Scripts/InstallPackages.R
cd /usr/bin
sudo Revo64-9.0 --vanilla --quiet  <  ~/InstallPackages.R

#######################################################################################################################################
#######################################################################################################################################
## END
#######################################################################################################################################
#######################################################################################################################################

