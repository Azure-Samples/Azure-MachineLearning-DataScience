################################################################################
#    Copyright (c) Microsoft. All rights reserved.
#    
#    Apache 2.0 License
#    
#    You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
#    
#    Unless required by applicable law or agreed to in writing, software 
#    distributed under the License is distributed on an "AS IS" BASIS, 
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or 
#    implied. See the License for the specific language governing 
#    permissions and limitations under the License.
#
################################################################################
param([string]$AccountPassword, [string]$IPythonPassword)
$previous_pwd = $pwd

$sysDrive = (Get-ChildItem env:SYSTEMDRIVE).Value
$web_client = new-object System.Net.WebClient
$pathToAnaconda =  $sysDrive + "\Anaconda"
$notebook_dir =  $env:userprofile + "\Documents\IPython Notebooks"
$script_dir = $env:userprofile + "\Documents\Data Science Scripts"

function DownloadAndInstall($DownloadPath, $ArgsForInstall, $DownloadFileType = "exe")
{
    $LocalPath = [IO.Path]::GetTempFileName() + "." + $DownloadFileType
    $web_client.DownloadFile($DownloadPath, $LocalPath)

    Start-Process -FilePath $LocalPath -ArgumentList $ArgsForInstall -Wait
}

function InstallAnacondaAndPythonDependencies
{
    if (-Not $(Test-Path $pathToAnaconda))
    {
        Write-Output "Anaconda Not Installed.  Installing... (This may take a while)"
        ##### Install Anaconda #####
        #Downloading And Install Anaconda
        $anaconda_url = "http://09c8d0b2229f813c1b93-c95ac804525aac4b6dba79b00b39d1d3.r79.cf1.rackcdn.com/Anaconda-2.1.0-Windows-x86_64.exe"
        $argumentList = "/S /D="+ $pathToAnaconda
        DownloadAndInstall -DownloadPath $anaconda_url -ArgsForInstall $argumentList

        #Anaconda adds itself to the path, but unfortunately after the python2.7 install.  We override this by setting the path here.
        $addToPath =  $pathToAnaconda+ ";"  + $pathToAnaconda + "\Scripts;" + $sysDrive + "\python27;" 
        [Environment]::SetEnvironmentVariable("Path", $addToPath + $env:Path, "Machine")
        $env:Path=[System.Environment]::GetEnvironmentVariable("Path","Machine")
    }

    Write-Output "Install jsonschema"
    Start-Process -FilePath "$pathToAnaconda\scripts\pip" -ArgumentList "install jsonschema" -Wait

    Write-Output "Updating IPython"
    Start-Process -FilePath "$pathToAnaconda\scripts\conda.exe" -ArgumentList "update --yes ipython=3.0" -Wait

    Write-Output "Updating Pandas"
    Start-Process -FilePath "$pathToAnaconda\scripts\conda.exe" -ArgumentList "update --yes pandas" -Wait

    Write-Output "pip install/upgrade azure"
    Start-Process -FilePath "$pathToAnaconda\scripts\pip" -ArgumentList "install -U azure" -Wait

    Write-Output "pip install/upgrade azureml"
    Start-Process -FilePath "$pathToAnaconda\scripts\pip" -ArgumentList "install -U azureml" -Wait

    Write-Output "easy_install pyodbc"
    Start-Process -FilePath "$pathToAnaconda\scripts\easy_install" -ArgumentList "https://pyodbc.googlecode.com/files/pyodbc-3.0.7.win-amd64-py2.7.exe" -Wait
}

function InstallOpenSSL
{
    $opensslInstallDir = Join-Path $Env:ProgramFiles 'OpenSSL'
    if(-Not $(Test-Path $opensslInstallDir))
    {
        Write-Output "Install VC++ 2008"
        DownloadAndInstall -DownloadPath "http://download.microsoft.com/download/1/1/1/1116b75a-9ec3-481a-a3c8-1777b5381140/vcredist_x86.exe" -ArgsForInstall "/Q ADDEPLOY=1"
        Write-Output "Install OpenSSL Light"
        $silentArgs = '/silent /verysilent /sp- /suppressmsgboxes /DIR="' + $opensslInstallDir + '"'
        DownloadAndInstall -DownloadPath "http://slproweb.com/download/Win32OpenSSL_Light-1_0_2c.exe" -ArgsForInstall $silentArgs

        # Add Config to the path.
        $env:Path = $env:path + ";$opensslInstallDir\bin"
        $env:openssl_conf = $opensslInstallDir + "\bin\openssl.cfg"
        # set these permanently after setting for our session
        [System.Environment]::SetEnvironmentVariable("PATH", $env:Path, "Machine")
        [System.Environment]::SetEnvironmentVariable("openssl_conf", $env:openssl_conf)

        "Path and OpenSSL Conf"
        $env:Path
        $env:OpenSSL_conf
    }
}

function SetupIPythonNotebookService
{
    Write-Output "Open port on firewall for IPython"
    Import-Module NetSecurity
    New-NetFirewallRule -Action Allow `
        -Name Allow_IPython `
        -DisplayName "Allow IPython" `
        -Description "Local 9999 Port for IPython Traffic" `
        -Profile Any `
        -Protocol TCP `
        -LocalPort 9999
    InstallOpenSSL

    $opensslInstallDir = Join-Path $Env:ProgramFiles 'OpenSSL'
    $IPythonProfile = Join-Path $env:userprofile ".ipython\profile_nbserver"

    if(-Not $(Test-Path $IPythonProfile))
    {
        # set config and IPython
        Write-Output "Creating NBServer"
        Start-Process -FilePath "$pathToAnaconda\scripts\ipython.exe" -ArgumentList "profile create nbserver" -Wait
        cd $IPythonProfile

        Write-Output "Creating Certificate for IPython"
        iex "OpenSSL req -x509 -nodes -days 365 -subj '/C=US/ST=WA/L=Redmond/CN=cloudapp.net' -newkey rsa:1024 -keyout mycert.pem -out mycert.pem"

        if ($IPythonPassword) {
            Write-Output "Using supplied password for your Notebook"
            $passwordHash = iex "$(Join-Path $pathToAnaconda python.exe) -c 'import IPython;print IPython.lib.passwd(''$IPythonPassword'')'" | Tee-Object -Variable passwordHash
        }
        else {
            # NOTE: THIS PROMPTS THE USER
            Write-Output "We need you to create a password for your Notebook...  PLEASE ENTER IN A PASSWORD BELOW..."
            $passwordHash = iex "$(Join-Path $pathToAnaconda python.exe) -c 'import IPython;print IPython.lib.passwd()'" | Tee-Object -Variable passwordHash
            if($passwordHash -is [system.array]){ $passwordHash = $passwordHash[-1] }
        }

        if (!(Test-Path $notebook_dir)) {
            mkdir $notebook_dir
        }

        $PathToConfigFile = "ipython_notebook_config.py"
        Write-Output "Generating the $PathToConfigFile file."  

        $file = @(
            "c = get_config()",
            "# This starts plotting support always with matplotlib",
            "c.IPKernelApp.pylab = 'inline'",
            "",
            "# You must give the path to the certificate file.",
            "",
            "# If using a Windows VM:",
            $("c.NotebookApp.certfile = r'" + $env:userprofile + "\.ipython\profile_nbserver\mycert.pem'"),
            "",
            "# Create your own password as indicated above",
            $("c.NotebookApp.password = u'" + $passwordHash + "'"),
            "",
            "# Network and browser details. We use a fixed port (9999) so it matches",
            "# our Azure setup, where we've allowed traffic on that port",
            "",
            "c.NotebookApp.ip = '*'",
            "c.NotebookApp.port = 9999",
            "c.NotebookApp.open_browser = False",
            $("c.FileNotebookManager.notebook_dir = r'" + $notebook_dir + "'")
        )
        $file | Out-File $PathToConfigFile -Append -Encoding UTF8
    }
}

function ScheduleAndStartIPython(){
    Write-Output "Scheduling Startup Task for the IPython Notebook Service"

    $ipython_dir = Join-Path $env:userprofile ".ipython"

    $taskName = "Start_IPython_Notebook"
    $argument = "/c `"cd $ipython_dir & C:\Anaconda\scripts\ipython.exe notebook --profile=nbserver`""
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument $argument -WorkingDirectory $ipython_dir
    $trigger = New-ScheduledTaskTrigger -AtStartup
    # Don't stop the task and let it run forever
    $settings = New-ScheduledTaskSettingsSet -DontStopOnIdleEnd -ExecutionTimeLimit ([TimeSpan]::Zero)
    
    # Register Task.  Get password and null out as soon as done.
    $username = [Environment]::UserName
    if ($AccountPassword) {
        Write-Output "Using supplied account password"
    }
    else {
        Write-Output "In order to start IPython each time the machine starts we need the password for your current account ($username)"
        $SecureAccountPassword = Read-Host -Prompt "Enter the password for account '$username'" -AsSecureString
        $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $SecureAccountPassword 
        $AccountPassword = $Credentials.GetNetworkCredential().Password 
    } 
    Register-ScheduledTask $taskName -Action $action -Trigger $trigger -Settings $settings -User "${username}" -Password "${AccountPassword}"
    $AccountPassword = $null

    # If the user wants to stop the auto restart of IPython run 'Unregister-ScheduledTask Start_IPython_Notebook'
    Write-Output "Starting IPython Notebook Service"
    Start-ScheduledTask -TaskName $taskName
}

function SetupSQLServerAccess
{
    Write-Output "Open port on firewall for SQL Server"
    Import-Module NetSecurity
    New-NetFirewallRule -Action Allow `
        -Name Allow_SQL_Server `
        -DisplayName "Allow SQL Server" `
        -Description "Local 1433 Port for SQL Server Traffic" `
        -Profile Any `
        -Protocol TCP `
        -LocalPort 1433
}

function DownloadRawFromGitWithFileList($base_url, $file_list_name, $destination_dir)
{   
    if (!(Test-Path $destination_dir)) {
        mkdir $destination_dir
    }

    # Download the list so we can iterate over it.
    $tempPath = [IO.Path]::GetTempFileName()
    $url = $base_url + $file_list_name
    $web_client.DownloadFile($url, $tempPath)

    # Iterate over the different lines in the file and add them to the machine
    $reader = [System.IO.File]::OpenText($tempPath)
    try {
        for(;;) {
            $line = $reader.ReadLine()
            if ($line -eq $null) { break }
           
            # download the file specified by this line...
            $url = $base_url + $line
            $destination = Join-Path $destination_dir $line
            $web_client.DownloadFile($url, $destination)
        }
    }
    finally {
        $reader.Close()
    }
}

function GetSampleFilesFromGit($gitdir_name, $list_name, $destination_dir){
    #Write-Output "Getting Sample Notebooks from Azure-MachineLearning-DataScience Git Repository"
    $file_url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/" + $gitdir_name + "/"
    DownloadRawFromGitWithFileList $file_url $list_name $destination_dir
}

function InstallAzureStorageExplorer(){
    # Download Storage Explorer in .zip
    $LocalPath = [IO.Path]::GetTempFileName() + ".zip"
    Invoke-WebRequest 'http://azurestorageexplorer.codeplex.com/downloads/get/891668' -OutFile $LocalPath

    # Unzip to get the exe.
    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    $ExtractDirectory = [IO.Path]::GetTempFileName() # makes file, delete file and mkdir
    rm $ExtractDirectory
    mkdir $ExtractDirectory
    [System.IO.Compression.ZipFile]::ExtractToDirectory($LocalPath, $ExtractDirectory)

    # Run installer with args
    Start-Process -FilePath "${ExtractDirectory}\AzureStorageExplorer3Preview1.exe" -ArgumentList "/S /v/qn"
}

function InstallAzureUtilities(){
    # Install AzCopy
    Write-Output "Install Azure Utilities: AzCopy"
    DownloadAndInstall "http://aka.ms/downloadazcopy" "/quiet" "msi"
    [Environment]::SetEnvironmentVariable("Path", "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\AzCopy;" + $env:Path, "Machine")

    # Install Azure Storage Explorer
    Write-Output "Install Azure Utilities: Azure Storage Explorer"
    InstallAzureStorageExplorer   
}

###################### End of Functions / Start of Script ######################
Write-Output "This script has been tested against the Azure Virtual Machine Images for 'Windows Server 2012 R2 Datacenter' and 'SQL Server 2012'"
Write-Output "Other OS Versions may work but are not officially supported."

InstallAnacondaAndPythonDependencies
#GetSampleNotebooksFromGit
#GetSampleScriptsFromGit
Write-Output "Fetching the sample IPython Notebooks..."
$dest_dir = $notebook_dir + "\DataScienceSamples"
GetSampleFilesFromGit "iPythonNotebooks" "Notebook_List.txt" $dest_dir
Write-Output "Fetching the sample script files..."
$dest_dir = $script_dir
GetSampleFilesFromGit "DataScienceScripts" "Script_List.txt" $dest_dir
InstallAzureUtilities
SetupIPythonNotebookService
ScheduleAndStartIPython
SetupSQLServerAccess

# Log that this script was run so we have usage numbers.
$web_client.DownloadString("http://go.microsoft.com/fwlink/?LinkId=526230") | Out-Null

cd $previous_pwd
