#######################################################################################################################################
## THIS SCRIPT CUSTOMIZES THE DSVM BY ADDING HADOOP AND YARN, STARTING RSTUDIO SERVER, AND DOWNLOADING DATA-SETS FOR OPERATIONALIZATION
## USING MICROSOFT R SERVER TUTORIAL AT MLADS SPRING 2017.
#######################################################################################################################################

mv code/ /home/remoteuser
mv docs/ /home/remoteuser
mv scripts/ /home/remoteuser
mv Readme.md /home/remoteuser


#!/bin/bash
printf "Setting up hadoop ... \n"
source /etc/profile.d/hadoop.sh

#######################################################################################################################################
## Setup autossh for hadoop service account
#######################################################################################################################################
echo -e 'y\n' | ssh-keygen -t rsa -P '' -f ~hadoop/.ssh/id_rsa
cat ~hadoop/.ssh/id_rsa.pub >> ~hadoop/.ssh/authorized_keys
chmod 0600 ~hadoop/.ssh/authorized_keys
chown hadoop:hadoop ~hadoop/.ssh/id_rsa
chown hadoop:hadoop ~hadoop/.ssh/id_rsa.pub
chown hadoop:hadoop ~hadoop/.ssh/authorized_keys

#######################################################################################################################################
## Start up several services, yarn, hadoop, rstudio server
#######################################################################################################################################
printf "Starting services ... \n"
systemctl start hadoop-namenode hadoop-datanode hadoop-yarn rstudio-server


#######################################################################################################################################
# Copy data and code to VM
#######################################################################################################################################
# printf "Downloading spark configuration files ... \n"

# Copy Spark configuration files & shell script
cd /home/remoteuser/scripts
mv spark-defaults.conf /dsvm/tools/spark/current/conf
mv log4j.properties /dsvm/tools/spark/current/conf


printf "Downloading data files ... \n"
## DOWNLOAD ALL DATA FILES
cd /home/remoteuser
mkdir data
cd data
# Airline data
wget https://vpgeneralblob.blob.core.windows.net/aitutorial/AirlineData/AirlineSubsetCsv.tar.gz
gunzip AirlineSubsetCsv.tar.gz
tar -xvf AirlineSubsetCsv.tar
rm AirlineSubsetCsv.tar

printf "Copying files to HDFS ... \n"
## Copy data to HDFS

# Make hdfs directories and copy things over to HDFS
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/rserve2
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/rserve2/Predictions
/opt/hadoop/current/bin/hadoop fs -chmod -R 777 /user/RevoShare/rserve2

/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser/Data
/opt/hadoop/current/bin/hadoop fs -mkdir /user/RevoShare/remoteuser/Models
/opt/hadoop/current/bin/hadoop fs -copyFromLocal * /user/RevoShare/remoteuser/Data


#######################################################################################################################################
#######################################################################################################################################
printf "Changing directory ownership ... \n"

## Change ownership of some of directories
cd /home/remoteuser/
chown -R remoteuser code data

su hadoop -c "/opt/hadoop/current/bin/hadoop fs -chown -R remoteuser /user/RevoShare/rserve2" 
su hadoop -c "/opt/hadoop/current/bin/hadoop fs -chown -R remoteuser /user/RevoShare/remoteuser" 

#######################################################################################################################################
#######################################################################################################################################
printf "Link to radmin ... \n"

cat <<EOF >/usr/local/bin/radmin
sudo /usr/local/bin/dotnet \
/usr/lib64/microsoft-deployr/9.0.1/Microsoft.DeployR.Utils.AdminUtil/Microsoft.DeployR.Utils.AdminUtil.dll
EOF


printf "Done! \n"
