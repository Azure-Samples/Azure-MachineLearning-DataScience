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

# Initiate WebClient
$web_client = new-object System.Net.WebClient

# Specify download directory and filepath
$destination_dir = "C:\RSpark";
if (!(Test-Path $destination_dir)) {mkdir $destination_dir}
$destination_file = Join-Path $destination_dir "RSpark_KDD2016.zip";
cd $destination_dir

# Specify which file to download
$url = "http://cdspsparksamples.blob.core.windows.net/hdiscripts/KDD2016R/RSpark_KDD2016.zip";

# Download and inflate file using unzip.exe
$web_client.DownloadFile($url, $destination_file)
unzip.exe .\RSpark_KDD2016.zip -d .


# End of Functions / Start of Script 
Write-Output "Completed getting zip files and inflating."
cd $destination_dir\RSpark_KDD2016

#######################################################################
# END
#######################################################################
