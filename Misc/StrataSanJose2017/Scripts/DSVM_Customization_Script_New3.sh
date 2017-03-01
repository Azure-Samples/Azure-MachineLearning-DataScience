#!/bin/bash

cat /opt/hadoop/.ssh/id_rsa.pub >> /opt/hadoop/.ssh/authorized_keys
chmod 0600 /opt/hadoop/.ssh/authorized_keys
chown hadoop /opt/hadoop/.ssh/authorized_keys

systemctl start hadoop-namenode hadoop-datanode hadoop-yarn rstudio-server

cd /home/remoteuser

