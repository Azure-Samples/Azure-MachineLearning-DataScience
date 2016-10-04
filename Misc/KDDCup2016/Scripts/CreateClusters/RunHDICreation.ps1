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


#######################################################################
# Get version of  Azure PowerShell cmdlet
#######################################################################
#(Get-Module -ListAvailable | Where-Object{ $_.Name -eq 'Azure' }) | Select Version, Name, Author, PowerShellVersion  | Format-List;

#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
$AzProfile = Login-AzureRmAccount

#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
$basepath = "C:\RSpark\RSpark_KDD2016"
#######################################################################
# READ IN CLUSTER CONFIGURATION PARAMETERS
#######################################################################
#READ IN PARAMETER CSV CONFIGURATION FILE
$paramFile = Import-Csv $basepath\Configuration\ClusterParameters.csv

# GET ALL THE PARAMETERS FROM THE CONFIGURATION PARAMETER FILE
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $AzProfile.Context.Tenant.TenantId;
$resourcegroup = $paramFile | Where-Object {$_.Parameter -eq "ResourceGroup"} | % {$_.Value}
$tmp = $paramFile | Where-Object {$_.Parameter -eq "Profilepath"} | % {$_.Value};  $profilepath = $basepath + "\Configuration\" + [string]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterStartIndex"} | % {$_.Value}; $clusterstartindex = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterEndIndex"} | % {$_.Value}; $clusterendindex = [int]$tmp;
$clusterprefix = $paramFile | Where-Object {$_.Parameter -eq "ClusterPrefix"} | % {$_.Value}
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterInfoOutputFileName"} | % {$_.Value}; $clusterinfooutputfilename = $basepath + "\" + [string]$tmp 
$tmp = $paramFile | Where-Object {$_.Parameter -eq "NumWorkerNodes"} | % {$_.Value}; $numworkernodes = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "AdminUsername"} | % {$_.Value}; $adminusername = [string]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "SshUsername"} | % {$_.Value}; $sshusername = [string]$tmp;


#######################################################################
# SET AZURE SUBSCRIPTIONS & SAVE PROFILE INFORMATION IN A FILE
#######################################################################
Set-AzureRmContext -SubscriptionID $subscriptionid -TenantID $tenantid
Save-AzureRmProfile -force -Path $profilepath

#######################################################################
# SUBMIT CLUSTER JOBS TO BE RUN IN PARALLEL
# NOTE: YOU NEED TO SPECIFY THE LOCATION OF FUNCTION FILE
#######################################################################
for($i=$clusterstartindex; $i -le $clusterendindex; $i++) {
	$clustername = $clusterprefix+$i;
	# Generates a random number between 1 and 100000 and adds it to the clustername for the cluster password 
	$randnum = Get-Random -minimum 1 -maximum 1000001
	$clusterpasswd = $clustername.substring(0,1).toupper() + $clustername.substring(1).tolower() + "_" + $randnum
	
	# Outputs the cluster login and password information to a file
	$clustername,$clusterpasswd -join ',' | out-file -filepath $clusterinfooutputfilename -append -Width 200;

	## SPECIFY ABSOLUTE PATH TO THE SCRIPT THAT YOU WANT TO SUBMIT AND RUN IN PARALLEL 
    Start-Job -ScriptBlock {C:\RSpark\RSpark_KDD2016\CreateClusters\SubmitHDICreation.ps1 $args[0] $args[1] $args[2] $args[3] $args[4] $args[5] $args[6]} -ArgumentList @($clustername, $resourcegroup, $profilepath, $clusterpasswd, $numworkernodes, $adminusername, $sshusername)
}

#######################################################################
# END
#######################################################################
