echo This program will kill Jupyter and ALL python process
echo Press CTRL-C IF THIS IS NOT YOU WANT ELSE PRESS ENTER
pause
taskkill /f /im jupyter.exe /im jupyter-notebook.exe /im python.exe
schtasks /Change  /TN start_ipython_notebook /DISABLE
