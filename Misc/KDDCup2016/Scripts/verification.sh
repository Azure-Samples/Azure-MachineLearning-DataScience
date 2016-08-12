amlAuth=$1

mkdir /tmp/verif

whoami > /tmp/verif/whoami
pwd > /tmp/verif/pwd
echo $amlAuth > /tmp/verif/amlAuth
