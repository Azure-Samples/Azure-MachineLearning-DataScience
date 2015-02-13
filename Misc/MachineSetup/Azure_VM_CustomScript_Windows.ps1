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
param(
    [string]$AccountName = $(throw "-AccountName is required."),
    [string]$AccountPassword = $(throw "-AccountPassword is required."),
    [string]$IPythonPassword = $(throw "-IPythonPassword is required.")
)

echo "Starting CustomScript process using the following parameters:"
echo "AccountName:$AccountName"
echo "AccountPassword:$AccountPassword"
echo "IPythonPassword:$IPythonPassword"

# Download the AzureML Windows setup script
$web_client = new-object System.Net.WebClient
$url="https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/MachineSetup/Azure_VM_Setup_Windows.ps1"
$ps1Path = [IO.Path]::GetTempFileName() + ".ps1"
$web_client.DownloadFile($url, $ps1Path)

# Run the setup script as the account user
$SecureAccountPassword = ConvertTo-SecureString $AccountPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("${env:COMPUTERNAME}\${AccountName}", $SecureAccountPassword)
Enable-PSRemoting -Force
Invoke-Command -FilePath $ps1Path -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList "${AccountPassword}", "${IPythonPassword}"
Disable-PSRemoting -Force
echo "Ending CustomScript process"

# Log that this script was run so we have usage numbers.
$web_client.DownloadString("http://pageviews.azurewebsites.net/pageview?Azure_VM_CustomScript_Windows.ps1") | Out-Null