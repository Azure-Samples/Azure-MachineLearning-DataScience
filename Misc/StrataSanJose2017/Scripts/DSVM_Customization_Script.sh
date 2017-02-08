#######################################################################################################################################
#######################################################################################################################################
## THIS SCRIPT CUSTOMIZES THE DSVM BY ADDING HADOOP AND YARN, INSTALLING R-PACKAGES, AND DOWNLOADING DATA-SETS FOR STRATA 
## SAN JOSE 2017 EXERCISES.
#######################################################################################################################################
#######################################################################################################################################
cd
wget http://cahandson.blob.core.windows.net/workshop/hadoopinstall.sh
chmod +x hadoopinstall.sh
./hadoopinstall.sh
export HADOOP_CONF_DIR=/opt/hadoop/hadoop-2.7.3/etc/hadoop

cd $SPARK_HOME
./bin/spark-submit --class org.apache.spark.examples.SparkPi --master yarn --deploy-mode client --driver-memory 1g --executor-memory 1g --executor-cores 1 ./examples/jars/spark-examples*.jar 10

cd
source .bash_profile
#######################################################################################################################################
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

####################
cd
cd Data
hadoop fs -mkdir /user/RevoShare/remoteuser/Data
hadoop fs -copyFromLocal * /user/RevoShare/remoteuser/Data
#######################################################################################################################################
#######################################################################################################################################

## START RSTUDIO
sudo rstudio-server start


#######################################################################################################################################
#######################################################################################################################################
# Install packages
cd
wget 
cd /usr/bin
sudo Revo64-9.0 --vanilla --quiet  <  /home/remoteuser/InstallPackages.R



#######################################################################################################################################
#######################################################################################################################################
## END
#######################################################################################################################################
#######################################################################################################################################
