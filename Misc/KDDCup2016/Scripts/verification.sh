amlAuth=$1

mkdir /tmp/verif
whoami > /tmp/verif/whoami
pwd > /tmp/verif/pwd
echo $amlAuth > /tmp/verif/amlAuth

Rscript --default-packages= /home/remoteuser/kddverification.r $amlAuth > /tmp/verif/rout.log 2> /tmp/verif/rerr.log
