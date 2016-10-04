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


param([string]$clustername, [string]$resourcegroup, [string]$profilepath, [string]$clusterpasswd, [int]$numworkernodes, [string]$adminusername, [string]$sshusername)

function SubmitHDICreation {
    param([string]$clustername, [string]$resourcegroup, [string]$profilepath, [string]$clusterpasswd, [int]$numworkernodes, [string]$adminusername, [string]$sshusername)
	$templatePath = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/Configuration/azuredeploy.json"; 
	Select-AzureRmProfile -Path $profilepath;
	
	$hdiparams = @{clusterType="spark";clusterName=$clustername;clusterLoginUserName=$adminusername;clusterLoginPassword=$clusterpasswd;sshUserName=$sshusername;sshPassword=$clusterpasswd;clusterWorkerNodeCount=$numworkernodes};
    New-AzureRmResourceGroupDeployment -Name $clustername -ResourceGroupName $resourcegroup -TemplateUri $templatePath -TemplateParameterObject $hdiparams;
}

SubmitHDICreation -clustername $clustername -resourcegroup $resourcegroup -profilepath $profilepath -clusterpasswd $clusterpasswd -numworkernodes $numworkernodes -adminusername $adminusername -sshusername $sshusername
