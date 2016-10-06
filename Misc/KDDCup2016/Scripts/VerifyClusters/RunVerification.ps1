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
# READ IN CLUSTER CONFIGURATION PARAMETERS
#######################################################################
#READ IN PARAMETER CSV CONFIGURATION FILE
$paramFile = Import-Csv $basepath\Configuration\ClusterParameters.csv

#GET ALL THE PARAMETERS FROM THE PARAMETER FILE
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $AzProfile.Context.Tenant.TenantId;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "Profilepath"} | % {$_.Value}; $profilepath = $basepath + "\Configuration\" + [string]$tmp
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterStartIndex"} | % {$_.Value}; $clusterstartindex = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterEndIndex"} | % {$_.Value}; $clusterendindex = [int]$tmp;
$clusterprefix = $paramFile | Where-Object {$_.Parameter -eq "ClusterPrefix"} | % {$_.Value}

#######################################################################
# SET AZURE SUBSCRIPTIONS & SAVE PROFILE INFORMATION IN A FILE
#######################################################################
Set-AzureRmContext -SubscriptionID $subscriptionid -TenantID $tenantid
Save-AzureRmProfile -force -Path $profilepath

#######################################################################
# SUBMIT CLUSTER JOBS TO BE RUN IN PARALLEL
# NOTE: YOU NEED TO SPECIFY THE LOCATION OF FUNCTION FILE
#######################################################################
for($i=$clusterstartIndex; $i -le $clusterendIndex; $i++) {
	$clustername = $clusterPrefix+$i;
	Start-Job -ScriptBlock {C:\RSpark\RSpark_KDD2016\VerifyClusters\SubmitVerification.ps1 $args[0] $args[1]} -ArgumentList @($clustername, $profilepath)
}
#######################################################################
# END
#######################################################################
