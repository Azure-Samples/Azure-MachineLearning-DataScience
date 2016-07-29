param([string]$clustername, [string]$clustername, [string]$resourcegroup, [string]$profilepath, [string]$clusterpasswd)

function SubmitHDICreation {
    param([string]$clustername, [string]$resourcegroup, [string]$profilepath, [string]$clusterpasswd)
	$templatePath = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/azuredeploy.json"; 
	Select-AzureRmProfile -Path $profilepath;
	
	$hdiparams = @{clusterType="spark";clusterName=$clustername;clusterLoginUserName="admin";clusterLoginPassword=$clusterpasswd;sshUserName="remoteuser";sshPassword=$clusterpasswd;clusterWorkerNodeCount=2};
    New-AzureRmResourceGroupDeployment -Name $clustername -ResourceGroupName $resourcegroup -TemplateUri $templatePath -TemplateParameterObject $hdiparams;
}

SubmitHDICreation -clustername $clustername -resourcegroup $resourcegroup -profilepath $profilepath -clusterpasswd $clusterpasswd
