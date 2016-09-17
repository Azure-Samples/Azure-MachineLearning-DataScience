param([string]$clustername, [string]$resourcegroup, [string]$profilepath)

function SubmitHDIClusterDeletion {
    param([string]$clustername, [string]$resourcegroup, [string]$profilepath)
	
	# Get profile from saved profile
    Select-AzureRmProfile -Path $profilepath;
   	
	# Delete cluster
    Remove-AzureRmHDInsightCluster -ClusterName $clustername 

	# Remove storage account for cluster
	$storageName = $clustername+'storage';
	Remove-AzureRmStorageAccount -ResourceGroupName $resourcegroup -Name $storageName
}

SubmitHDIClusterDeletion -clustername $clustername -resourcegroup $resourcegroup -profilepath $profilepath
