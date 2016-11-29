schtasks /Change  /TN start_ipython_notebook /ENABLE
schtasks /Run  /TN start_ipython_notebook
echo Enabled and Started Jupyter Notebook Server
