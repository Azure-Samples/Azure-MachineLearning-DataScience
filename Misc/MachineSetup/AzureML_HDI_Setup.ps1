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

$sysDrive = (Get-ChildItem env:SYSTEMDRIVE).Value
$web_client = new-object System.Net.WebClient

function InstallAnacondaAndPythonDependencies
{
    ##### Install Anaconda #####
    #Downloading Anaconda
    $anaconda_url = "http://09c8d0b2229f813c1b93-c95ac804525aac4b6dba79b00b39d1d3.r79.cf1.rackcdn.com/Anaconda-2.1.0-Windows-x86_64.exe"
    $local_anaconda_file = $pwd.path + "\anaconda.exe"
    $web_client.DownloadFile($anaconda_url, $local_anaconda_file)

    #Installing Anaconda
    $pathToAnaconda=  $sysDrive + "\Anaconda"
    $argumentList = "/S /D="+ $pathToAnaconda
    Start-Process -FilePath $local_anaconda_file -ArgumentList $argumentList -Wait

    #Anaconda adds itself to the path, but unfortunately after the python2.7 install.  We override this by setting the path here.
    $addToPath =  $pathToAnaconda+ ";"  + $pathToAnaconda + "\Scripts;" + $sysDrive + "\python27;" 
    [Environment]::SetEnvironmentVariable("Path", $addToPath + $env:Path, "Machine")

    # Update Pandas
    Start-Process -FilePath "$pathToAnaconda\scripts\conda.exe" -ArgumentList "update --yes pandas" -Wait

    # Install Azure
    Start-Process -FilePath "$pathToAnaconda\scripts\pip" -ArgumentList "install -U azure" -Wait

    # Install AzureML
    # Note: this isn't available yet so is currently a noop
    Start-Process -FilePath "$pathToAnaconda\scripts\pip" -ArgumentList "install -U azureml" -Wait

    Write-Output "easy_install pyodbc"
    Start-Process -FilePath "$pathToAnaconda\scripts\easy_install" -ArgumentList "https://pyodbc.googlecode.com/files/pyodbc-3.0.7.win-amd64-py2.7.exe" -Wait
}

function UnzipFile($File, $Destination)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($File, $Destination)
}

function GetGitRepoToLocalFolder($GithubZipFile, $LocalFolder)
{
    $GithubZipFile = $GithubZipFile + "/archive/master.zip"
    $tempPath = [IO.Path]::GetTempFileName() + ".zip"
    $web_client.DownloadFile($GithubZipFile, $tempPath)
    UnzipFile -File $tempPath -Destination $LocalFolder 
}

InstallAnacondaAndPythonDependencies

# Gets entire git repo
# GetGitRepoToLocalFolder -GithubZipFile "https://github.com/Azure/Azure-MachineLearning-DataScience" -LocalFolder "$sysDrive\Git"

# In order to set the path from the Hive Queries we need to restart the nodemanager service
if ((Get-WMIObject win32_service | Where-Object {$_.name -eq "nodemanager"})) 
{
    Restart-Service nodemanager;
}


# Log that this script was run so we have usage numbers.
$web_client.DownloadString("http://pageviews.azurewebsites.net/pageview?AzureML_HDI_Setup.ps1") | Out-Null
