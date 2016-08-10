
function printarray($arrayname)
{
    $rowcount = 0
    foreach($name in $arrayname)
    {
        $rowcount = $rowcount + 1
        $echostring = '['+$rowcount+']: '+$name
        echo $echostring
    }
}

function mountfileservices
{
    # Authenticate to Azure.
    
    Write-Host "Start getting the list of subscriptions under your Azure account..." -ForegroundColor Yellow
    Try
    {
        $sublist = Get-AzureRmSubscription
    }
    Catch
    {
        Write-Host "You have not logged in yet. Please log in first..." -ForegroundColor Yellow
        Login-AzureRmAccount
        $sublist = Get-AzureRmSubscription
    }
    $subnamelist = $sublist.SubscriptionName
    Write-Host "Here are the subscription names under your Azure account:" -ForegroundColor Yellow
    printarray $subnamelist
    # Select your subscription
    $inputfileyesorno = Read-Host "Do you have a file with the information of the file share you want to mount?[Y]-yes/N-no"
    if (!($inputfileyesorno.ToLower() -eq 'n'))
    {
        $inputfileyesorno = 'y'
    }
    $sub = 'NA'
    $sa = 'NA'
    $sharename = 'NA'
    if (!$inputfileyesorno -or ($inputfileyesorno.ToLower() -eq 'y'))
    {
        $inputfilequit = $false
        $inputfileright = $false
        while (!$inputfilequit -and !$inputfileright)
        {
            $filename = Read-Host "Please provide the name of the file with the information of the file share you want to mount"
            if (!$filename)
            {
                $retryinput = Read-Host "File name cannot be empty. [R]-retry/S-skip"
                if ($retryinput.ToLower() -eq 's')
                {
                    $inputfilequit = $true
                }
            }
            else
            {
                if (!(Test-Path $filename))
                {
                    $retryinput = Read-Host "File does not exit. [R]-retry/S-skip"
                    if ($retryinput.ToLower() -eq 's')
                    {
                        $inputfilequit = $true
                    }
                }
                else
                {
                    $inputfileright = $true
                }
            }
        }
        if ($inputfileright)
        {
            $filecontent = Get-Content $filename
            foreach ($line in $filecontent)
            {
                $fields = $line.Split(":")
                switch($fields[0])
                {
                    "Subscription name" {$sub = $fields[1]}
                    "Storage account name" {$sa = $fields[1]}
                    "File share name" {$sharename = $fields[1]}
                }
            }
            if (($sub -eq 'NA') -or ($sa -eq 'NA') -or ($sharename -eq 'NA'))
            {
                Write-Host 'Information about the file share to be mounted is incomplete. You have to manually input information later.' -ForegroundColor Yellow
                $sub = 'NA'
                $sa = 'NA'
                $sharename = 'NA'
            }
        }
    }
        

    $subnameright = $false
    $quitornot = $false
    
    DO
    {
        if ($sub -eq 'NA')
        {
            $sub = Read-Host 'Enter the subscription name where the Azure file share service has been created'
        }
        $index = [array]::indexof($subnamelist,$sub)
        if ($index -ge 0)
        {
            $subnameright = $true
        } else
        {
            $quitornotask = Read-Host 'The subscription name you input does not exist. [R]-retry/Q-quit'
            $sub = 'NA'
            $sa = 'NA'
            $sharename = 'NA'
            if ($quitornotask.ToLower() -eq 'q')
            {
                Write-Host "Mounting Azure file share service quit." -ForegroundColor "Red"
                $quitornot = $true
            }
        }
    } while(!$subnameright -and !$quitornot)
    
    if ($subnameright){
        $retrycount = 0
        $getstoragesucceed = $false
        Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
        Write-Host "Start getting the list of storage accounts under your subscription "$sub -ForegroundColor Yellow
        while (!$getstoragesucceed -and ($retrycount -lt 10))
        {
            $storageaccountlist = Get-AzureRmStorageAccount -ErrorAction SilentlyContinue -WarningAction SilentlyContinue #Retrieve the storage account list
            if ($storageaccountlist.Length -gt 0) #if not returning empty
            {
                $getstoragesucceed = $true #succeeded
            }
            if (!$getstoragesucceed) #if not succeeded, try one more time
            {
                $retrycount = $retrycount + 1
                Write-Host "Trial "$retrycount" failed to get storage account list from your subscription "$sub". Wait for 1 second to try again."
                Start-sleep -s 1
            }
        }
        if (!$getstoragesucceed -and ($retrycount -eq 10))
        {
            Write-Host "It has failed 10 times getting the storage account. Retry sometime later." -ForegroundColor Red
        }
        else
        {
            $storageaccountnames = $storageaccountlist.StorageAccountName #get the storage account names
            $resourcegroupnames = $storageaccountlist.ResourceGroupName #get the resource group for storage accounts
            Write-Host "Here are the storage account names under subsription "$sub
            printarray $storageaccountnames
            $goodsaname = $false
            $quitornot = $false
            while (!$goodsaname -and !$quitornot)
            {
                if ($sa -eq 'NA')
                {
                    $prompt1 = "Enter the index of the storage account name where your Azure file share you want to mount is created (1-"+$storageaccountnames.Length+")"
                    $saindex = Read-Host $prompt1
                    if ($saindex -gt 0 -and $saindex -le $storageaccountnames.Length)
                    {
                        $sa = $storageaccountnames[$saindex-1]
                        $rg = $resourcegroupnames[$saindex-1]
                        $goodsaname = $true
                    }
                    else
                    {
                        $prompt1 = "Index out of bounds (1-"+$storageaccountnames.Length+").[R]-retry/Q-quit"
                        $quitsa = Read-Host $prompt1
                        if ($quitsa.ToLower() -eq 'q')
                        {
                            $quitornot = $true
                        }
                    }
                } 
                else{
                    $saindex = [array]::IndexOf($storageaccountnames,$sa)
                    if ($saindex -lt 0)
                    {
                        Write-Host "Storage account name"$sa" from the file does not exist. Please manually input it next." -ForegroundColor Yellow
                        $sa = 'NA'
                        $sharename = 'NA'
                    }
                    else
                    {
                        $rg = $resourcegroupnames[$saindex]
                        $goodsaname = $true
                    }
                }
            }
            if ($goodsaname){
                $sharenameexist = $false
                $quitnewsharename = $false
                $storKey = (Get-AzureRmStorageAccountKey -Name $sa -ResourceGroupName $rg ).Value[0]
                $sharenameright = $false
                $quitornot = $false
                while ((!$sharenameexist) -and (!$quitnewsharename))
                {
                    while(!$sharenameright -and !$quitornot)
                    {
                        if ($sharename -eq 'NA')
                        {
                            $sharename = Read-Host 'Enter the name of the file share to mount (lower case only)'
                            $sharename = $sharename.ToLower()
                        }
                        if (!$sharename)
                        {
                            $quitornotanswer = Read-Host "File share name cannot be empty. [R]-retry/Q-quit"
                            if ($quitornotanswer.ToLower = 'q')
                            {
                                $quitornot = $true
                            }
                        } 
                        else
                        {
                            $sharenameright = $true
                        }
                    }
                    if ($sharenameright)
                    {
                        $drivenameright = $false
                        $existingdisks = [System.IO.DriveInfo]::getdrives()
                        $existingdisknames = $existingdisks.Name
                        Write-Host "Existing disk names are:" -ForegroundColor Yellow
                        printarray $existingdisknames
                        $quitdrivename = $false
                        while (!$drivenameright -and !$quitdrivename)
                        {
                            $drivename = Read-Host 'Enter the name of the drive to be added to your virtual machine. This name should be different from the disk names your virtual machine has.'
                            if (!($drivename[$drivename.Length-1] -eq ':')){
                                $drivename = $drivename+':'
                            }
                            $drivename1 = $drivename+"\"
                            $diskindex = [array]::IndexOf($existingdisknames, $drivename1)
                            if ($diskindex -ge 0)
                            {
                                $prompt1 = "The disk drive"+$drivename+" you want to mount the file share as already exists. [R]-retry/Q-quit"
                                $inputnewdrive = Read-Host $prompt1
                                if ($inputnewdrive.ToLower() -eq 'q')
                                {
                                    $quitdrivename = $true
                                }
                            }
                            else{
                                $drivenameright = $true
                            }
                        }
                        if ($drivenameright)
                        {

                            Write-Host 'File share '$sharename' will be mounted to your virtual machine as drive' $drivename
                            # Save key securely
                            cmdkey /add:$sa.file.core.windows.net /user:$sa /pass:$storKey

                            # Mount the Azure file share as  drive letter on the VM. 
                            try
                            {
                                net use $drivename \\$sa.file.core.windows.net\$sharename
                                $sharenameexist = $true
                            }
                            Catch
                            {
                                $newsharename = Read-Host "File share "$sharename "does not exist. [R]-retry/Q-quit"
                                if ($newsharename.ToLower() -eq 'q')
                                {
                                    $quitnewsharename = $true
                                    Write-Host "Quit mounting this file share." -ForegroundColor Yellow
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}



$prompt = "Do you want to mount an Azure file share service to your Azure virtual machine? [Y]-yes/N-no to quit."

$mountornot = Read-Host -Prompt $prompt
if (!$mountornot -or ($mountornot.ToLower() -eq 'y')){
	
	mountfileservices
	$others = $true
	DO{
		$prompt = "Do you want to mount other Azure file share services? [Y]-yes/N-no to quit."
		$mountornot = Read-Host -Prompt $prompt
		if (!$mountornot -or ($mountornot.ToLower() -eq 'y')){
			mountfileservices
		} else{
			$others = $false
		}
	} while($others)
}
