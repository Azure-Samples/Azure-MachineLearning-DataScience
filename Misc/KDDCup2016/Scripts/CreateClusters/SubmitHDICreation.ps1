param([string]$clustername, [string]$resourcegroup, [string]$profilepath, [string]$clusterpasswd, [int]$numworkernodes, [string]$adminusername, [string]$sshusername)

function SubmitHDICreation {
    param([string]$clustername, [string]$resourcegroup, [string]$profilepath, [string]$clusterpasswd, [int]$numworkernodes, [string]$adminusername, [string]$sshusername)
	$templatePath = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/azuredeploy.json"; 
	Select-AzureRmProfile -Path $profilepath;
	
	$hdiparams = @{clusterType="spark";clusterName=$clustername;clusterLoginUserName=$adminusername;clusterLoginPassword=$clusterpasswd;sshUserName=$sshusername;sshPassword=$clusterpasswd;clusterWorkerNodeCount=$numworkernodes};
    New-AzureRmResourceGroupDeployment -Name $clustername -ResourceGroupName $resourcegroup -TemplateUri $templatePath -TemplateParameterObject $hdiparams;
}

SubmitHDICreation -clustername $clustername -resourcegroup $resourcegroup -profilepath $profilepath -clusterpasswd $clusterpasswd -numworkernodes $numworkernodes -adminusername $adminusername -sshusername $sshusername
