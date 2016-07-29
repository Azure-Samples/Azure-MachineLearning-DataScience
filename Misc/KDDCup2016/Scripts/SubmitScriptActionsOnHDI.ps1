param([string]$clustername, [string]$profilepath)

function SubmitScriptActionsOnHDI {
    param([string]$clustername, [string]$profilepath)
	$saName = "RpackageInstalls" 
	$saURI = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/downloadRun.sh" 
	$rstudioName = "RStudioInstall"
	$rstudioURI = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/KDDCup2016/Scripts/RStudioInstall.sh"
	$nodeTypes = "edgenode"
	Select-AzureRmProfile -Path $profilepath;
	
	Submit-AzureRmHDInsightScriptAction -ClusterName $clustername -Name $saName -Uri $saURI -NodeTypes $nodeTypes
	Submit-AzureRmHDInsightScriptAction -ClusterName $clustername -Name $rstudioName -Uri $rstudioURI -NodeTypes $nodeTypes
}

SubmitScriptActionsOnHDI -clustername $clustername -profilepath $profilepath
