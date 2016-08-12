amlAuth=$1
apiKey=$2

mkdir /tmp/verif

whoami > /tmp/verif/whoami
pwd > /tmp/verif/pwd
echo $amlAuth > /tmp/verif/amlAuth
echo $apiKey > /tmp/verif/apiKey
