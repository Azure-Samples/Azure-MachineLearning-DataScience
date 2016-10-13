cd C:\Windows\temp

Import-Module BitsTransfer
Start-BitsTransfer -Source https://deeplearningtoolkit.blob.core.windows.net/assets/dsvm-deep-learning-v4.zip -Destination ".\dsvm-deep-learning.zip"
Start-BitsTransfer -Source https://deeplearningtoolkit.blob.core.windows.net/assets/mxnet.zip -Destination ".\mxnet.zip"
Start-BitsTransfer -Source https://deeplearningtoolkit.blob.core.windows.net/assets/cuda_8.0.44_windows.zip -Destination ".\cuda_8.0.44_windows.zip"
unzip dsvm-deep-learning.zip
unzip mxnet.zip
unzip cuda_8.0.44_windows.zip

# cuda
certutil -addstore "TrustedPublisher" dsvm-deep-learning\nvidia_certificate.cer
cuda_8.0.44_windows\setup.exe -s | wait-process
$env:Path += ";C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v8.0\bin;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v8.0\libnvvp;C:\Program Files\NVIDIA Corporation\NVSMI"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)

# CNTK GPU version
cd dsvm-deep-learning
Remove-Item C:\dsvm\tools\cntk\* -Recurse
Copy-Item -Recurse CNTK-1-7-Windows-64bit-GPU\* C:\dsvm\tools\cntk
Remove-Item C:\dsvm\tools\bin\cntk.exe
Copy-Item CNTK-1-7-Windows-64bit-GPU\cntk\cntk.exe C:\dsvm\tools\bin
$env:Path += ";C:\dsvm\tools\cntk\cntk"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
cd ..

# mxnet 
Copy-Item -Recurse mxnet\lib\* C:\dsvm\tools\mxnet\lib
$env:Path += ";C:\dsvm\tools\mxnet\lib"
$env:mxnet_path = "C:\dsvm\tools\mxnet"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("mxnet_path", $env:mxnet_path, [System.EnvironmentVariableTarget]::Machine)

# python
cd mxnet\python
python setup.py install
cd ..

# R
$R_path = "C:\Program Files\Microsoft SQL Server\130\R_SERVER\bin\x64\R.exe"
& $R_path -e "install.packages(c('argparse', 'Rcpp', 'DiagrammeR', 'data.table', 'jsonlite', 'magrittr', 'stringr'))"
& $R_PATH CMD INSTALL .\R-package
cd ..

# copy over the sample solutions
cd dsvm-deep-learning
mkdir C:\dsvm\deep-learning
mkdir C:\dsvm\deep-learning\solutions
Copy-Item -Recurse solutions\* C:\dsvm\deep-learning\solutions

# add the readme
Copy-Item readme.txt C:\dsvm\deep-learning
# and link to it on the desktop
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\deep learning toolkit readme.lnk")
$Shortcut.TargetPath = "C:\dsvm\deep-learning\readme.txt"
$Shortcut.Save()