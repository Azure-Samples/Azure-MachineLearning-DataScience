
cd C:\Windows\temp

Import-Module BitsTransfer
Start-BitsTransfer -Source https://deeplearningtoolkit.blob.core.windows.net/assets/dsvm-deep-learning.zip -Destination ".\dsvm-deep-learning.zip"
unzip dsvm-deep-learning.zip

cd dsvm-deep-learning

# replace mxnet
Copy-Item -Recurse mxnet\* C:\dsvm\tools\mxnet\

# install the NVIDIA driver
certutil -addstore "TrustedPublisher" nvidia_certificate.cer
cd nvidia-driver
.\setup.exe -s | Wait-Process
cd ..

# CNTK GPU version
Remove-Item C:\dsvm\tools\cntk\* -Recurse
Copy-Item -Recurse CNTK-1-7-Windows-64bit-GPU\* C:\dsvm\tools\cntk
Remove-Item C:\dsvm\tools\bin\cntk.exe
Copy-Item CNTK-1-7-Windows-64bit-GPU\cntk\cntk.exe C:\dsvm\tools\bin
$env:Path += ";C:\dsvm\tools\cntk\cntk"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# set up the environment
.\setupenv.cmd

# python installation
cd mxnet\python
python setup.py install
cd ..\..

# R installation
$R_path = "C:\Program Files\Microsoft SQL Server\130\R_SERVER\bin\x64\R.exe"
& $R_path -e "install.packages(c('Rcpp', 'DiagrammeR', 'data.table', 'jsonlite', 'magrittr', 'stringr'))"
& $R_path CMD INSTALL --no-multiarch R-package

# copy over the samples
mkdir C:\dsvm\deep-learning
mkdir C:\dsvm\deep-learning\solutions
Copy-Item 
Copy-Item -Recurse solutions\* C:\dsvm\deep-learning\solutions

# add the readme
Copy-Item readme.txt C:\dsvm\deep-learning
# and link to it on the desktop
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\deep learning toolkit readme.lnk")
$Shortcut.TargetPath = "C:\dsvm\deep-learning\readme.txt"
$Shortcut.Save()

# copy nvidia-smi
mkdir C:\dsvm\NVSMI
Copy-Item -Recurse NVSMI\* C:\dsvm\NVSMI\