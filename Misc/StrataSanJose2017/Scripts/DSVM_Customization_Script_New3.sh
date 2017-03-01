cat /opt/hadoop/.ssh/id_rsa.pub >> /opt/hadoop/.ssh/authorized_keys
chmod 0600 /opt/hadoop/.ssh/authorized_keys
chown hadoop /opt/hadoop/.ssh/authorized_keys

systemctl start hadoop-namenode hadoop-datanode hadoop-yarn rstudio-server

cd /home/remoteuser

hadoop fs -mkdir /user/RevoShare/rserve2
hadoop fs -mkdir /user/RevoShare/rserve2/Predictions
hadoop fs -chmod -R 777 /user/RevoShare/rserve2
hadoop fs -mkdir /user/RevoShare/remoteuser
hadoop fs -mkdir /user/RevoShare/remoteuser/Data
hadoop fs -mkdir /user/RevoShare/remoteuser/Models
