#!/bin/bash
npm install -g configurable-http-proxy
/anaconda/envs/py35/bin/pip install jupyterhub
mkdir /etc/jupyterhub
chmod +rx /etc/jupyterhub
cd /etc/jupyterhub
wget "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Data-Science-Virtual-Machine/Linux/extensions/JupyterHub/jupyterhub_config.py"
cd /etc/pam.d
wget "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Data-Science-Virtual-Machine/Linux/extensions/JupyterHub/pamdfile" -O jupyterhub
wget "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Data-Science-Virtual-Machine/Linux/extensions/JupyterHub/jupyterhub.service" -O /lib/systemd/system/jupyterhub.service
/anaconda/envs/py35/bin/jupyter notebook --generate-config --config=/etc/jupyterhub/default_jupyter_config.py
/anaconda/envs/py35/bin/pip install git+https://github.com/jupyter/sudospawner
mkdir /etc/jupyterhub/srv
cd /etc/jupyterhub/srv
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt -subj '/CN=dsvm/O=YY/C=XX'
mkdir /etc/skel/notebooks
cp /dsvm/Notebooks/*.ipynb /etc/skel/notebooks/

systemctl daemon-reload
systemctl start jupyterhub

# Create users and generate random password. Run as root
# u=`openssl rand -hex 2`;useradd user$u;p=`openssl rand -hex 10` ; echo $p | passwd user$u --stdin; echo user$u, $p
