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
param([string]$DestDir)

$web_client = new-object System.Net.WebClient


function DownloadRawFromGitWithFileList($base_url, $file_list_name, $destination_dir)
{   
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
    $file_url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/" + $gitdir_name + "/"
    DownloadRawFromGitWithFileList $file_url $list_name $destination_dir
}


###################### End of Functions / Start of Script ######################
if (!(Test-Path $DestDir)) {
    Write-Output "$DestDir does not exist and is created."
    mkdir $DestDir
}
Write-Output "Start downloading the data file to $DestDir. It may take a while..."
$file_url = "http://getgoing.blob.core.windows.net/public/nyctaxi1pct.csv"
$file_dest = Join-Path $DestDir "nyctaxi1pct.csv"
$web_client.DownloadFile($file_url, $file_dest)
Write-Output "Fetching the sample script files to $DestDir..."
GetSampleFilesFromGit "RSQL" "FilestoDownload_R_Walkthrough.txt" $DestDir
Write-Output "Fetching the sample script files completed."
Write-Output "Now entering the destination directory $DestDir."
cd $DestDir

