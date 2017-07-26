param([string]$vmname, [string]$resourcegroup, [string]$profilepath)

function SubmitDSVMDeletion {
    param([string]$vmname, [string]$resourcegroup, [string]$profilepath)
	
	# Get profile from saved profile
    Select-AzureRmProfile -Path $profilepath;
   	
	# Delete cluster
    Remove-AzureRmVM -ResourceGroupName $resourcegroup -Name $vmname -Force

	# Remove storage account for cluster
	$storageName = $vmname+'sjcstorage';
	Remove-AzureRmStorageAccount -ResourceGroupName $resourcegroup -Name $storageName -Force
	
	# Remove AzureRmNetworkInterface
	Remove-AzureRmNetworkInterface -ResourceGroupName $resourcegroup -Name $vmname -Force
	
	# Remove AzureNetworkSecurityGroup
	$nsgName = $vmname+'_NSG';
	Remove-AzureRmNetworkSecurityGroup -ResourceGroupName $resourcegroup -Name $nsgName -Force
	
	# Remove AzureRmPublicIpAddress
	Remove-AzureRmPublicIpAddress -ResourceGroupName $resourcegroup -Name $vmname -Force
	
	# Remove AzureRmVirtualNetwork
	Remove-AzureRmVirtualNetwork -ResourceGroupName $resourcegroup -Name $vmname -Force
	
}

SubmitDSVMDeletion -vmname $vmname -resourcegroup $resourcegroup -profilepath $profilepath
