    # Authenticate to Azure.
    if ((Get-AzureRmSubscription).Length -le 0) {
        Login-AzureRmAccount
    }

    $sa = Read-Host 'Enter the storage account name where file share is created '
    $rg = Read-Host 'Enter the resource group '
    $storKey = (Get-AzureRmStorageAccountKey -Name $sa -ResourceGroupName $rg )..Value[0]

    # Get Azure File Service Share details
    $sharename = Read-Host 'Enter the name of the file share to mount'
    $drivename = Read-Host 'Enter the name of the drive. This name should be different from the disk names your virtual machine has.'

    # Save key securely
    cmdkey /add:$sa.file.core.windows.net /user:$sa /pass:$storKey

    # Mount the Azure file share as  drive letter on the VM. 
    net use $drivename \\$sa.file.core.windows.net\$sharename

	$prompt = "Do you want to mount an Azure file share service to your Azure virtual machine? [Y]/N"
  
    $mountornot = Read-Host -Prompt $prompt
    if (!$mountornot -or $mountornot.ToLower() -eq 'y'){
        
        mountfileservices
        $others = 1
        DO{
            $prompt = "Do you want to mount other Azure file share services? [Y]/N"
            $mountornot = Read-Host -Prompt $prompt
            if (!$mountornot -or $mountornot.ToLower() -eq 'y'){
                mountfileservices
            } else{
                $others = 0
            }
        } while($others -eq 1)
    }
