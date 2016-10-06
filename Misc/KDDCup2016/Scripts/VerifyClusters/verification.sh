mkdir /tmp/verif
whoami > /tmp/verif/whoami
pwd > /tmp/verif/pwd

cd /home/remoteuser

if [[ -f ClusterVerification.R ]]; then sudo rm -Rf ClusterVerification.R; fi;

wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/VerifyClusters/ClusterVerification.R

Rscript --default-packages= /home/remoteuser/ClusterVerification.R > /tmp/verif/rout.log
