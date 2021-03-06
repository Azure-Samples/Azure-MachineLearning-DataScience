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

param([string]$clustername, [string]$profilepath)

function SubmitScriptActionsOnHDI {
    param([string]$clustername, [string]$profilepath)
	$saName = "RpackageInstalls" 
	$saURI = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/RunningScriptActions/downloadRun.sh" 
	$nodeTypes = "edgenode"
	Select-AzureRmProfile -Path $profilepath;
	
	Submit-AzureRmHDInsightScriptAction -ClusterName $clustername -Name $saName -Uri $saURI -NodeTypes $nodeTypes
}

SubmitScriptActionsOnHDI -clustername $clustername -profilepath $profilepath
