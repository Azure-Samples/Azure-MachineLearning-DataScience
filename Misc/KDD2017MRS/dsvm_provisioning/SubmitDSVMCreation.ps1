param([string]$vmname, [string]$resourcegroup, [string]$profilepath, [string]$adminPassword)

function SubmitDSVMCreation {
    param([string]$vmname, [string]$resourcegroup, [string]$profilepath, [string]$adminPassword)
	$templatePath = "C:\Users\vapaunic\repos\KDD2017R\Scripts\azuredeployDSVM.json"; 
	Select-AzureRmProfile -Path $profilepath;
	
	$dsvmparams = @{vmName=$vmname;adminUsername="remoteuser";adminPassword=$adminPassword};
    New-AzureRmResourceGroupDeployment -Name $vmname -ResourceGroupName $resourcegroup -TemplateUri $templatePath -TemplateParameterObject $dsvmparams;
}

SubmitDSVMCreation -vmname $vmname -resourcegroup $resourcegroup -profilepath $profilepath -adminPassword $adminPassword
