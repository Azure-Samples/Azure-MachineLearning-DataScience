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

# Authenticate to Azure.

$prompt = "Do you want to create an Azure file share service for your project? [Y]/N"
$createornot = Read-Host -Prompt $prompt
if (!$createornot -or ($createornot.ToLower() -eq 'y')){
	Write-Host "Getting the list of subscriptions..." -ForegroundColor Yellow
	try
	{
		$sublist = Get-AzureRmSubscription
	} 
	Catch
	{
		Write-Host "Login to Azure..." -ForegroundColor Yellow
		Login-AzureRmAccount
		$sublist = Get-AzureRmSubscription
	}
	
	$subnamelist = $sublist.SubscriptionName
	#$subnamecount = 0
	#foreach($subname in $subnamelist)
	#{
	#    $subnamecount = $subnamecount + 1
	#    $echostring = '['+$subnamecount+']: '+$subname
	#    echo $echostring
	#}
	printarray $subnamelist

	# Select your subscription
	$subnameright = $false
	$quitornot = $false
	DO
	{
		$promptstring = 'Enter the index of the subscription name where resources will be created(1-'+$subnamelist.Length+')'
		$subindex = Read-Host $promptstring
		#$index = [array]::indexof($subnamelist,$sub)

		if (([int]$subindex -gt 0) -and ([int]$subindex -le $subnamelist.Length)) #selected index is in the range of 1 to the number of subscriptions
		{
			
			$sub = $subnamelist[$subindex-1]
			$prompt1 = "You selected subscription ["+$subindex+"]:"+$sub+". [Y]-yes to continue/N-no to reselect"
			$selectedright = Read-Host $prompt1
			if (!$selectedright -or $selectedright.ToLower() -eq 'y')
			{
				$subnameright = $true
			}
		}
		if (!$subnameright)
		{
			$quitornotask = Read-Host 'The index of the subscription you selected is out of bounds. [R]-retry/Q-quit'
			if ($quitornotask.ToLower() -eq 'q')
			{
				Write-Host "Creating Azure file share service quit." -ForegroundColor "Red"
				$quitornot = $true
			}
		}
	} while(!$subnameright -and !$quitornot)

	if ($subnameright) #subscription name selected correctly
	{
		Write-Host "Getting the list of storage accounts under subscription "$sub -ForegroundColor Yellow
		Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
		$storageaccountlist = Get-AzureRmStorageAccount #Retrieve the storage account list
		$storageaccountnames = $storageaccountlist.StorageAccountName #get the storage account names
		Write-Host "Here are the storage account names under your subscription "$sub -ForegroundColor Yellow
		#echo $storageaccountnames
		#$sacount = 0
		#foreach($saname in $storageaccountnames)
		#{
		#    $sacount = $sacount + 1
		#    $echostring = '['+$sacount+']: '+$saname
		#    echo $echostring
		#}
		printarray $storageaccountnames

		$resourcegroupnames = $storageaccountlist.ResourceGroupName #get the resource group for storage accounts
		$createornotsa = Read-Host 'Do you want to create a new storage account for your Azure file share?[Y]/N'
		$saretryornot = 'r'
		if (!$createornotsa -or ($createornotsa.ToLower() -eq 'y')){ #create a new storage account
			$havegoodsaname = $false
			$saretry = $true
			$loc = 'southcentralus'
			while(!$havegoodsaname -and $saretry) {
				$sa0 = Read-Host 'Enter the storage account name to create (only accept lower case letters and numbers)'
				$sa = $sa0.ToLower()
				$sa = $sa -replace '[^a-z0-9]'
				if (!($sa -eq $sa0))
				{
					Write-Host "You input storage account name "$sa0 ". To follow the naming convention of Azure storage account names, it is converted to" $sa"." -ForegroundColor Yellow
				}
				$index = [array]::indexof($storageaccountnames,$sa)
				if ($index -ge 0) #storage accont name already exists. 
				{
					$rg = $resourcegroupnames[$index]
					$saretryornot = Read-Host "Storage Account already exists. [R]-retry/U-use/Q-quit"  #storage account already exists. Retry, use it, or quit.
					if ($saretryornot.ToLower() -eq 'q') #quit
					{
						$saretry = $false
					} ElseIf ($saretryornot.ToLower() -eq 'u')
					{
						$prompt1 = "You choose to use an existing storage account ["+($index+1)+"]:"+$sa+". [Y]-continue/R-retry"
						$useexisting = Read-Host $prompt1
						if (!$useexisting -or $useexisting.ToLower() -eq 'y')
						{
							$havegoodsaname = $true
							Write-Host "Existing storage account"$sa "will be used. Its resource group is"$rg -ForegroundColor Yellow
						}
					}
					
				} else{ #storage account does not exist
					Write-Host "Storage account" $sa "will be created..." -ForegroundColor Yellow
					Write-Host "You need to select the resource group name under which the storage account will be created." -ForegroundColor Yellow
					Write-Host "Here is the list of existing resource group names" -ForegroundColor Yellow
					#echo $resourcegroupnames
					#$rgcount = 0
					#foreach($rgname in $resourcegroupnames)
					#{
					#    $rgcount = $rgcount + 1
					#    $echostring = '['+$rgcount+']: '+$rgname
					#    echo $echostring
					#}
					printarray $resourcegroupnames
					
					$rgvalid = $false
					while (!$rgvalid)
					{
						$prompt1 = 'Enter the index of resource group name (0-New/1-'+$resourcegroupnames.Length+'-Use existing resource group)'
						$rg0 = Read-Host $prompt1
						if ($rg0 -eq 0)
						{
							$rg0 = Read-Host 'Please input the name of a new resource group to create(only allows lower case letters, numbers, underline, and hyphen)'
							$rg = $rg0 -Replace '[^a-zA-Z0-9-_]' #enforce the naming convention
							if (!($rg -eq $rg0))
							{
								Write-Host "The resource group name you input is "$rg0 ". To follow the naming convention of Azure resource group, it is converted to "$rg
							}
							$index = [array]::indexof($resourcegroupnames,$rg)
							if ($index -ge 0) #resource group exists
							{
								$prompt1 = "Resource group "+$rg+" exists (resource group ["+($index+1)+"]. [U]-use/R-retry"
								$useexisting = Read-Host $prompt1
								if (!$useexisting -or $useexisting.ToLower() -eq 'u')
								{
									$rgvalid = $true
								}
							}
							else
							{
								$rgvalid = $true
							}
						}
						else{
							if ($rg0 -gt 0 -and $rg0 -le $resourcegroupnames.Length)
							{
								$rg = $resourcegroupnames[$rg0-1]
								$prompt1 = "You selected resource group ["+$rg0+"]:"+$rg+". [Y]-continue/R-retry"
								$continue = Read-Host $prompt1
								if ($continue.ToLower() -eq 'y' -or !$continue)
								{
									$rgvalid = $true
								}
							}
							else
							{
								Write-Host 'Selected index of existing resource group output of bounds. Retry...' -ForegroundColor Yellow
							}
						}
					}
					$havegoodsaname = $true
					$index = [array]::indexof($resourcegroupnames,$rg)
					if ($index -ge 0){ #resource group already exists
						Write-Host "Start creating storage account"$sa "under resource group"$rg "at"$loc -ForegroundColor Yellow
						New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS' #create a new storage account under rg
					} else{
						Write-Host "Start creating resource group"$rg "at"$loc -ForegroundColor Yellow
						New-AzureRmResourceGroup -Name $rg -Location $loc
						Write-Host "Start creating storage account"$sa "under resource group"$rg "at"$loc -ForegroundColor Yellow
						New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
					}
				}
			}
			#if ($havegoodsaname -and $saretry) #a good name is provided, $saretryornot is not 'q', and the storage account name does not exist
			#{
			#    $index = [array]::indexof($resourcegroupnames,$rg)
			#    if ($index -ge 0){
			#        Write-Host "Using the existing resource group "$rg -ForegroundColor Yellow
			#    } else{
			#        
			#        Write-Host "Resource group "$rg "does not exist. Creating..." -ForegroundColor Yellow
			#        New-AzureRmResourceGroup -Name $rg -Location $loc
			#    }
			#    if (!($saretryornot.ToLower() -eq 'u')) #not using the existing storage account
			#    {
			#        Write-Host "Start creating storage account "$sa "under resource group "$rg "at "$loc -ForegroundColor Yellow
			#        New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
			#    }
			#}            
		} else{ #use an existing storage account
			$validexistingsasaname = $false
			$saretry = $true
			while(!$validexistingsasaname -and $saretry) {
				$prompt1 = 'Enter the index of the storage account to use(1-'+$storageaccountnames.Length+')'
				$saindex = Read-Host $prompt1
				if ([int]$saindex -gt 0 -and [int]$saindex -le $storageaccountnames.Length) #storage accont name already exists. 
				{
					$sa = $storageaccountnames[$saindex-1]
					$rg = $resourcegroupnames[$saindex-1]
					$prompt1 = "You selected storage account ["+$saindex+"]:"+$sa+".[Y]-continue/N-reselect"
					$saconfirm = Read-Host $prompt1
					if (!$saconfirm -or $saconfirm.ToLower() -eq 'y')
					{
						Write-Host "Storage Account"$sa "is selected. Its resource group is"$rg -ForegroundColor Yellow  #storage account exists. 
						$validexistingsasaname = $true
					}
				} else{
					$saretryornot = Read-Host "Selected index of storage account out of bounds. [R]-retry/Q-quit"
					if ($saretryornot.ToLower() -eq 'q')
					{
						$saretry = $false
						Write-Host "Quitting... " -ForegroundColor Yellow
					}
				}
			}
		}
		
		Set-AzureRmCurrentStorageAccount -ResourceGroupName $rg -StorageAccountName $sa

		# Create a Azure File Service Share
		$validsharename = $false
		$quitcreateshare = $false
		while (!$validsharename -and !$quitcreateshare)
		{
			$sharename0 = Read-Host 'Enter the name of the file share service to create (lower case characters, numbers, and - are accepted)'
			if (!$sharename0)
			{
				$retrysharename = Read-Host 'You entered an empty file share name. [R]-retry/Q-quit'
				if ($retrysharename.ToLower() -eq 'q')
				{
					$quitcreateshare = $true
				}
			}
			else
			{
				$sharename = $sharename0.ToLower()
				$sharename = $sharename -Replace '[^a-z0-9-]'
				if (!($sharename -eq $sharename0))
				{
					Write-Host "Invalid file share name "$sharename0 " converted to "$sharename -ForegroundColor Yellow
				}
				if (!($sharename[0] -match "[a-z0-9]") -or ($sharename -match "--"))
				{
					
					$retrysharename = Read-Host "Invalid file share name. File share name cannot start with non-alphanumeric characters. It cannot have -- either.[R]-retry/Q-quit"
					if ($retrysharename.ToLower() -eq 'q')
					{
						$quitcreateshare = $true
					}
				}
				else
				{
					$validsharename = $true
				}
			}
		}

		if ($validsharename)
		{
			$s = New-AzureStorageShare $sharename
			# Create a directory under the FIle share. You can give it any name
			New-AzureStorageDirectory -Share $s -Path 'data' 
			# List the share to confirm that everything worked
			Get-AzureStorageFile -Share $s
			Write-Host "An Azure file share service created. It can be later mounted to the Azure virtual machines created for your team projects." -ForegroundColor "Green"
			Write-Host "Please keep a note for the information of the Azure file share service. It will be needed in the future when mounting it to Azure virtual machines" -ForegroundColor "Green"
			$outputtofile = Read-Host "Do you want to output the file share information to a file in your current directory?[Y]/N"
			if (!$outputtofile -or ($outputtofile.ToLower() -eq 'y'))
			{
				$filenameright = $false
				$skipoutputfile = $false
				while(!$filenameright -and !$skipoutputfile)
				{
					$filename=Read-Host "Please provide the file name. This file under the current working directory will be created to store the file share information."
					if (!$filename)
					{
						Write-Host "File name cannot be empty." -ForegroundColor Yellow
					}
					else
					{
						$filename=$PWD.Path+'\'+$filename
						if (Test-Path $filename)
						{
							$fileoutput = Read-Host $filename "already exists. [R]-retry/Q-quit"
							if ($fileoutput.ToLower() -eq 'q')
							{
								$skipoutputfile = $true
							}
						}
						else
						{
							$filenameright = $true
						}
					}
				}
				if ($filenameright)
				{
					$now = Get-Date -format "MM/dd/yyyy HH:mm"
					"Created date time:"+$now >> $filename
					"Subscription name:"+$sub >> $filename
					"Storage account name:"+$sa >> $filename
					"File share name:"+$sharename >> $filename
					Write-Host "File share information output to"$filename". Share it with your team members who want to mount it to their virtual machines." -ForegroundColor Yellow
				}
			}

		}
	}
}

