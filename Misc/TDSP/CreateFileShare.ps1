Login-AzureRmAccount
Get-AzureRmSubscription | Format-Table
# Select your subscription
$sub = Read-Host 'Select the subscription name where resources will be created'
Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
$createornotsa = Read-Host 'Do you want to create a new storage account for your file share?'
if (!$createornotsa -or $createornotsa.ToLower() -eq 'y'){
    $havegoodsaname = $false
    while(!$havegoodsaname) {
        $sa = Read-Host 'Enter the storage account name to create'
        $havegoodsaname = !(Test-AzureName -Storage $sa)
        if (!$havegoodsaname) { Write-Host "Storage Account already exists. Try a different name again." }
    }
    $rg = Read-Host 'Enter the resource group'

    # Create a new resource group if it does not exist. Default is southcentral (for now)
    $loc = 'southcentralus'
    try {
        $tmprg=Get-AzureRmResourceGroup -Name $rg
        Write-Host "Reusing Resource Group: "$rg
        $loc=$tmprg.Location
    }
    catch {
        New-AzureRmResourceGroup -Name $rg -Location $loc
    }
    # Create a new storage account. You can reuse existing storage account if you wish.
    New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
    # Set your current working storage account
} else {
    Get-AzureRmStorageAccount | Format-Table
    $sa = Read-Host 'Enter the storage account name to reuse from above list'
    $rg = Read-Host 'Enter the resource group of thr storage account from above list'            
}
Set-AzureRmCurrentStorageAccount -ResourceGroupName $rg -StorageAccountName $sa

# Create a Azure File Service Share
$sharename = Read-Host 'Enter the name of the file share service to create'
$s = New-AzureStorageShare $sharename
# Create a directory under the FIle share. You can give it any name
New-AzureStorageDirectory -Share $s -Path 'data' 
# List the share to confirm that everything worked
Get-AzureStorageFile -Share $s
Write-Host "An Azure file share service created. It can be later mounted to the Azure virtual machines created for your team projects." -ForegroundColor "Green"
Write-Host "Please keep a note for the information of the Azure file share service. It will be needed in the future when mounting it to Azure virtual machines" -ForegroundColor "Green"
