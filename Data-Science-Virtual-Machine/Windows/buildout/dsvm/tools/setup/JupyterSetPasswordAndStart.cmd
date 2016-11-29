@echo off
echo This tool will help you set your Jupyter Password and Enable the Jupyter server task (named start_ipython_notebook) in task scheduler
c:\anaconda\python.exe -c "import IPython;p=IPython.lib.passwd();f=open('c:\\programdata\\jupyter\\jupyter_notebook_config.py', 'a');f.write('\nc.NotebookApp.password = u\''+p+'\'');f.close()"
if errorlevel 1 exit /b 1
echo Updated the Jupyter config c:\\programdata\\jupyter\\jupyter_notebook_config.py
pause
schtasks /Change  /TN start_ipython_notebook /ENABLE
schtasks /Run  /TN start_ipython_notebook 
echo Enabled and Started Jupyter Notebook Server
echo You can access Jupyter server by entering https://localhost:9999/ locally on the browser
echo You can also access Jupyter server remotely from a browser by entering https://[machine IP or DNS name]:9999/ 
pause
@echo on

