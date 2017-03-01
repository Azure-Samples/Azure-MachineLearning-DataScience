#######################################################################################################################################
#######################################################################################################################################
## THIS SCRIPT CUSTOMIZES THE DSVM BY ADDING HADOOP AND YARN, INSTALLING R-PACKAGES, AND DOWNLOADING DATA-SETS FOR STRATA 
## SAN JOSE 2017 EXERCISES.
#######################################################################################################################################
#######################################################################################################################################
#!/bin/bash
source /etc/profile.d/hadoop.sh

#######################################################################################################################################
## Setup autossh for hadoop service account
#######################################################################################################################################
cat /opt/hadoop/.ssh/id_rsa.pub >> /opt/hadoop/.ssh/authorized_keys
chmod 0600 /opt/hadoop/.ssh/authorized_keys
chown hadoop /opt/hadoop/.ssh/authorized_keys

#######################################################################################################################################
## Start up several services, yarn, hadoop, rstudio server
#######################################################################################################################################
systemctl start hadoop-namenode hadoop-datanode hadoop-yarn rstudio-server

#######################################################################################################################################
## MRS Deploy Setup
#######################################################################################################################################
cd /home/remoteuser
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Scripts/backend_appsettings.json
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Scripts/webapi_appsettings.json

mv backend_appsettings.json /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.BackEnd/appsettings.json
mv webapi_appsettings.json /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.WebAPI/appsettings.json

cp /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.WebAPI/autoStartScriptsLinux/*    /etc/systemd/system/.
cp /usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Server.BackEnd/autoStartScriptsLinux/*   /etc/systemd/system/.
systemctl enable frontend
systemctl enable rserve
systemctl enable backend
systemctl start frontend
systemctl start rserve
systemctl start backend
#https://msdn.microsoft.com/en-us/microsoft-r/operationalize/admin-utility
#cd /usr/lib64/microsoft-deployr/9.0.1
#/usr/local/bin/dotnet Microsoft.DeployR.Utils.AdminUtil/Microsoft.DeployR.Utils.AdminUtil.dll

#######################################################################################################################################
# Copy data and code to VM
#######################################################################################################################################
cd /home/remoteuser
mkdir  Data Code
mkdir Code/MRS Code/sparklyr Code/SparkR

## DOWNLOAD ALL CODE FILES
cd /home/remoteuser
cd Code/MRS
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/1-Clean-Join-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/2-Train-Test-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/3-Deploy-Score-Subset.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/SetComputeContext.r
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/MRS/azureml-settings.json

cd /home/remoteuser
cd Code/SparkR
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/SparkR/SparkR_NYCTaxi_forDSVM.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/SparkR/SparkR_NYCTaxi_forDSVM.html

cd
cd Code/sparklyr
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/sparklyr/sparklyr_NYCTaxi_forDSVM.Rmd
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Code/sparklyr/sparklyr_NYCTaxi_forDSVM.html

## DOWNLOAD ALL DATA FILES
# NYC Taxi data
cd /home/remoteuser
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
cd /home/remoteuser
cd Data

/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/rserve2
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/rserve2/Predictions
/opt/hadoop/current/bin/hadoop fs -chmod -R 777 /user/RevoShare/rserve2

/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser/Data
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser/Models

/opt/hadoop/current/bin/hadoop fs -copyFromLocal * /user/RevoShare/remoteuser/Data

#######################################################################################################################################
#######################################################################################################################################
# Install R packages
cd /home/remoteuser
wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/StrataSanJose2017/Scripts/InstallPackages.R

cd /usr/bin
Revo64-9.0 --vanilla --quiet  <  /home/remoteuser/InstallPackages.R

#######################################################################################################################################
#######################################################################################################################################
## END
#######################################################################################################################################
#######################################################################################################################################
