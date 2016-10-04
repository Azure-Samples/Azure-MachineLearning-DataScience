amlAuth=$1

mkdir /tmp/verif
whoami > /tmp/verif/whoami
pwd > /tmp/verif/pwd
# echo $amlAuth > /tmp/verif/amlAuth

cd /home/remoteuser

if [[ -f ClusterVerification.R ]]; then sudo rm -Rf ClusterVerification.R; fi;

wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/kddverification.r

#Rscript --default-packages= /home/remoteuser/ClusterVerification.R $amlAuth > /tmp/verif/rout.log
#Rscript --default-packages= /home/remoteuser/ClusterVerification.R $amlAuth > /tmp/verif/rout.log
