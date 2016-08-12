amlAuth=$1

mkdir /tmp/verif
whoami > /tmp/verif/whoami
pwd > /tmp/verif/pwd
# echo $amlAuth > /tmp/verif/amlAuth

cd /home/remoteuser

if [[ -f kddverification.r ]]; then sudo rm -Rf kddverification.r; fi;

wget https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/kddverification.r

Rscript --default-packages= /home/remoteuser/kddverification.r $amlAuth > /tmp/verif/rout.log 2> /tmp/verif/rerr.log
