
cd /home/remoteuser
wget https://github.com/rstudio/sparklyr/archive/df9de9a5c52a89ae025483652d2c033162f185cd.zip -O sparklyr0801.zip
unzip sparklyr0801.zip
tar -czvf sparklyr0801.tar.gz sparklyr-df9de9a5c52a89ae025483652d2c033162f185cd

sudo R --vanilla --quiet  <  /home/remoteuser/update_sparklyr.R


