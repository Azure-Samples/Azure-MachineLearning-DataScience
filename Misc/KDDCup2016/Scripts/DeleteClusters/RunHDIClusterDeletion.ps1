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
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
$AzProfile = Login-AzureRmAccount

#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
$basepath = "C:\RSpark\RSpark_KDD2016"

#######################################################################
# READ IN PARAMETERS
#######################################################################
#READ IN PARAMETER CSV FILE
$paramFile = Import-Csv $basepath\Configuration\ClusterParameters.csv

#GET ALL THE PARAMETERS FROM THE PARAMETER FILE
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $AzProfile.Context.Tenant.TenantId;
$resourcegroup = $paramFile | Where-Object {$_.Parameter -eq "ResourceGroup"} | % {$_.Value}
$tmp = $paramFile | Where-Object {$_.Parameter -eq "Profilepath"} | % {$_.Value};  $profilepath = $basepath + "\Configuration\" + [string]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterStartIndex"} | % {$_.Value}; $clusterstartindex = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterEndIndex"} | % {$_.Value}; $clusterendindex = [int]$tmp;
$clusterprefix = $paramFile | Where-Object {$_.Parameter -eq "ClusterPrefix"} | % {$_.Value}

#######################################################################
# SET AZURE SUBSCRIPTIONS & SAVE PROFILE INFORMATION IN A FILE
#######################################################################
Set-AzureRmContext -SubscriptionID $subscriptionid -TenantID $tenantid
Save-AzureRmProfile -force -Path $profilepath

#######################################################################
# INDICATE START AND END INDEXES OF CLUSTERS
#######################################################################
for($i=$clusterstartindex; $i -le $clusterendindex; $i++){
    # Delete cluster
	$clustername = $clusterPrefix+$i;
	Start-Job -ScriptBlock {C:\RSpark\RSpark_KDD2016\ClusterDeletion\SubmitHDIClusterDeletion.ps1 $args[0] $args[1] $args[2]} -ArgumentList @($clustername, $resourcegroup, $profilepath)
	# Delete storage account
	$storageName = $clustername+'storage';
	Remove-AzureRmStorageAccount -force -ResourceGroupName $resourcegroup -Name $storageName
}
