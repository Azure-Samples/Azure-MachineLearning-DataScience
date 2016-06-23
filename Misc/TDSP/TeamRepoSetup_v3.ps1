$role = Read-Host -Prompt 'Select your role in your team:1-team lead;[2]-project lead;3-project team member'
$vstsyesorno = Read-Host -Prompt 'Do you want to set up your team or project repository on Visual Studio Team Services (VSTS)?[Y]/N'
if (!$vstsyesorno -or $vstsyesorno.ToLower() -eq 'y')
{
    $server = Read-Host -Prompt 'Please input your VSTS server name'
    
    if (!$role -or !$role -eq 1 -or !$role -eq 3){
        $role = 2
    }
    if ($role -eq 2){
        $name1 = 'team repository'
        $name2 = 'project repository'
    } elseif ($role -eq 1){
        $name1 = 'general repository'
        $name2 = 'team repository'
    } else{
        $name1 = 'project repository'
    }

    if ($role -lt 3){
        $prompt1 = 'Input the name of the '+$name1
        $prompt2 = 'Input the name of the '+$name2
        $generalreponame = Read-Host -Prompt $prompt1
        $teamreponame  = Read-Host -Prompt $prompt2
        $generalreponame = [uri]::EscapeDataString($generalreponame)
        $teamreponame = [uri]::EscapeDataString($teamreponame)
        $generalrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$generalreponame
        $teamrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$teamreponame
        Write-host "URL of the "$name1 "is "$generalrepourl -ForegroundColor "Yellow"
        Write-host "URL of the "$name2 "is "$teamrepourl -ForegroundColor "Yellow"
    } else{
        $prompt1 = 'Input the name of the '+$name1
        $generalreponame = [uri]::EscapeDataString($generalreponame)
        $generalrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$generalreponame
        Write-host "URL of the "$name1 "is "$generalrepourl -ForegroundColor "Yellow"
    }
    
    $rootdir = $PWD.Path

    Write-host "Installing Chocolatey. It is needed to install Git Credential Manager." -ForegroundColor "Yellow"
    iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
    Write-host "Chocolatey installed." -ForegroundColor "Green"

    Write-host "Installing Git Credential Manager..." -ForegroundColor "Yellow"
    choco install git-credential-manager-for-windows -y
    Write-host "Git Credential manager installed." -ForegroundColor "Green"

    Write-host "Start cloning the"$name1"..." -ForegroundColor "Yellow"
    Write-host "You might be asked to input your credentials..." -ForegroundColor "Yellow"
    git clone $generalrepourl
    Write-host $name1" cloned." -ForegroundColor "Green"

    if ($role -lt 3){
        Write-host "Start cloning"$name2"..." -ForegroundColor "Yellow"
        Write-host "Currently it is empty. You need to determine the content of it..." -ForegroundColor "Yellow"
        git clone $teamrepourl
        Write-host $name2"cloned." -ForegroundColor "Green"
    }

    if ($role -lt 3)
    {
        Write-host "Copying the entire directory in "$rootdir"\"$generalreponame "except .git directory to "$rootdir"\"$teamreponame"..." -ForegroundColor "Yellow"
        $SourceDirectory = $rootdir+"\"+$generalreponame
        $DestinationDirectory = $rootdir+"\"+$teamreponame
        $ExcludeSubDirectory = $SourceDirectory+'\.git'
        $files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }
        $promptnote = 'n'
        $copied = 'n'
        foreach ($file in $files)
        {
            $CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
            if ((Test-Path $CopyPath) -and ($promptnote -eq 'n' -or $promptnote -eq 'y')){
                $promptnote = $CopyPath+" exists. Do you want to overwrite?[a]-all,y-yes,n-no"
                $overwriteyesno = Read-Host -Prompt $promptnote
                if (!$overwriteyesno -or $overwriteyesno.ToLower() -eq 'a')
                {
                    $overwriteyesno = 'a'
                } ElseIf ($overwriteyesno.ToLower() -eq 'y')
                {
                    $overwriteyesno = 'y'
                } 
            } else {
                $overwriteyesno = 'y'
            }
            if ($overwriteyesno -eq 'y' -or $overwriteyesno -eq 'a')
            {
                Copy-Item $file.FullName -Destination $CopyPath -Force
                $copied = 'y'
            }
        }

        if ($copied = 'y')
        {
            Write-host $name1 "copied to the "$name2" on your disk." -ForegroundColor "Green"
        }
        Write-host "Change to the "$name2 "directory "$DestinationDirectory -ForegroundColor "Green"
        cd $DestinationDirectory

        $prompt = 'If you are ready to commit the'+$name2+', enter Y. Otherwise, go to change your'+$name2+'and come back to enter Y to commit...'
        $commitornot = Read-Host -Prompt $prompt

        if ($commitornot.ToLower() -eq 'y')
        {
            git add .
            $username = git config user.name
            $email = git config user.email
            if (!$username)
            {
                $user = Read-Host -Prompt 'For logging purpose, input your name'
                git config --global user.name $user
            }
            if (!$email)
            {
                $useremail = Read-Host -Prompt 'Fog logging purpose, input your email address'
                git config --global user.email $useremail
            }
            git commit -m"changed the team repository directory."
            git push
        } else {
            Write-host "I do not understand your input. Please commit later by yourself using the following commands in sequence." -ForegroundColor "Yellow"
            Write-host "These commands need to be submitted when you are in "$DestinationDirectory
            Write-host "git add ." -ForegroundColor "Green"
            Write-host "git config --global user.name john.smith" -ForegroundColor "Green"
            Write-host "git config --global user.email johnsmith@example.com" -ForegroundColor "Green"
            Write-host "git commit -m'This is a commit note'" -ForegroundColor "Green"
            Write-host "git push" -ForegroundColor "Green"
        }
    }
}

# Authenticate to Azure.
if ($role -lt 3){
    if ($role -eq 1){
        $prompt = "Do you want to create an Azure file share service for your team? [Y]/N"
    }
    else {
        $prompt = "Do you want to create an Azure file share service for your project? [Y]/N"
    }
    $createornot = Read-Host -Prompt $prompt
    if (!$createornot -or $createornot.ToLower() -eq 'y'){
        Login-AzureRmAccount
        $sublist = Get-AzureRmSubscription
        $subnamelist = $sublist.SubscriptionName
        echo $subnamelist
        # Select your subscription
        $subnameright = $false
        $quitornot = $false
        DO
        {
            $sub = Read-Host 'Enter the subscription name where resources will be created'
            if ($subnamelist -match $sub)
            {
                $index = [array]::indexof($subnamelist,$sub)
                if ($index -ge 0)
                {
                    $subnameright = $true
                }
            } 
            if (!$subnameright)
            {
                $quitornotask = Read-Host 'The subscription name you input does not exist. [R]-retry,q-quit'
                if ($quitornotask -eq 'q')
                {
                    Write-Host "Creating Azure file share service quit." -ForegroundColor "Red"
                    $quitornot = $true
                }
            }
        } while(!$subnameright -and !$quitornot)

        if ($subnameright) #subscription name selected correctly
        {
            Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
            $storageaccountlist = Get-AzureRmStorageAccount #Retrieve the storage account list
            $storageaccountnames = $storageaccountlist.StorageAccountName #get the storage account names
            Write-Host "Here are the storage account names under your subscription "$sub -ForegroundColor Yellow
            echo $storageaccountnames
            $resourcegroupnames = $storageaccountlist.ResourceGroupName #get the resource group for storage accounts
            $createornotsa = Read-Host 'Do you want to create a new storage account for your Azure file share?[Y]/N'
            $saretryornot = 'r'
            if (!$createornotsa -or $createornotsa.ToLower() -eq 'y'){ #create a new storage account
                $havegoodsaname = $false
                $saretry = $true
                $loc = 'southcentralus'
                while(!$havegoodsaname -and $saretry) {
                    $sa0 = Read-Host 'Enter the storage account name to create (only accept lower case letters and numbers)'
                    $sa = $sa0.ToLower()
                    $sa = $sa -replace '[^a-z0-9]'
                    if (!$sa -eq $sa0)
                    {
                        Write-Host "You input storage account name "$sa0 ". To follow the naming convention of Azure storage account names, it is converted to" $sa"." -ForegroundColor Yellow
                    }
                    $index = [array]::indexof($storageaccountnames,$sa)
                    if ($index -ge 0) #storage accont name already exists. 
                    {
                        $rg = $resourcegroupnames[$index]
                        $saretryornot = Read-Host "Storage Account already exists. [R]-retry,U-use,Q-quit"  #storage account already exists. Retry, use it, or quit.
                        if ($saretryornot.ToLower() -eq 'q') #quit
                        {
                            $saretry = $false
                        } ElseIf ($saretryornot.ToLower() -eq 'u')
                        {
                            $havegoodsaname = $true
                            Write-Host "Existing storage account "$sa "will be used. Its resource group is "$rg -ForegroundColor Yellow
                        }
                        
                    } else{ #storage account does not exit
                        Write-Host "Storage account" $sa "will be created..." -ForegroundColor Yellow
                        Write-Host "You need to select the resource group name under which the storage account will be created." -ForegroundColor Yellow
                        Write-Host "Here is the list of existing resource group names" -ForegroundColor Yellow
                        echo $resourcegroupnames
                        $rg0 = Read-Host 'Enter the resource group name (New or existing names are OK. Only alphanumeric, underscore, and hyphen are accepted)'
                        $rg = $rg0 -Replace '[^a-zA-Z0-9-_]' #enforce the naming convention
                        if (!$rg -eq $rg0)
                        {
                            Write-Host "The resource group name you input is "$rg0 ". To follow the naming convention of Azure resource group, it is converted to "$rg0
                        }
                        $havegoodsaname = $true
                        $index = [array]::indexof($resourcegroupnames,$rg)
                        if ($index -ge 0){ #resource group already exists
                            New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS' #create a new storage account under rg
                        } else{
                            New-AzureRmResourceGroup -Name $rg -Location $loc
                            New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
                        }
                    }
                }
                if ($havegoodsaname -and $saretry) #a good name is provided, $saretryornot is not 'q', and the storage account name does not exist
                {
                    $index = [array]::indexof($resourcegroupnames,$rg)
                    if ($index -ge 0){
                        Write-Host "Using the existing resource group "$rg -ForegroundColor Yellow
                    } else{
                        
                        Write-Host "Resource group "$rg "does not exist. Creating..." -ForegroundColor Yellow
                        New-AzureRmResourceGroup -Name $rg -Location $loc
                    }
                    if (!$saretryornot.ToLower() -eq 'u') #not using the existing storage account
                    {
                        New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location $loc -Type 'Standard_LRS'
                    }
                }            
            } else{ #use an existing storage account
                $validexistingsasaname = $false
                $saretry = $true
                while(!$validexistingsasaname -and $saretry) {
                    $sa0 = Read-Host 'Enter the storage account name to use'
                    $sa = $sa0.ToLower()
                    if ($storageaccountnames -match $sa) #storage accont name already exists. 
                    {
                        $index = [array]::indexof($storageaccountnames,$sa)
                        $rg = $resourcegroupnames[$index]
                        Write-Host "Storage Account "$sa "does exist. Its resource group is "$rg -ForegroundColor Yellow  #storage account exists. 
                        $validexistingsasaname = $true
                    } else{
                        $saretryornot = Read-Host $sa "does not exit. [R]-retry,Q-quit"
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
            $sharename = Read-Host 'Enter the name of the file share service to create'
            $s = New-AzureStorageShare $sharename
            # Create a directory under the FIle share. You can give it any name
            New-AzureStorageDirectory -Share $s -Path 'data' 
            # List the share to confirm that everything worked
            Get-AzureStorageFile -Share $s
            Write-Host "An Azure file share service created. It can be later mounted to the Azure virtual machines created for your team projects." -ForegroundColor "Green"
            Write-Host "Please keep a note for the information of the Azure file share service. It will be needed in the future when mounting it to Azure virtual machines" -ForegroundColor "Green"
        }
    }
}

function mountfileservices
{
    # Authenticate to Azure.
    if ((Get-AzureRmSubscription).Length -le 0) {
        Login-AzureRmAccount
    }
    
    $sublist = Get-AzureRmSubscription
    $subnamelist = $sublist.SubscriptionName
    echo $subnamelist
    # Select your subscription
    $subnameright = $false
    $quitornot = $false
    DO
    {
        $sub = Read-Host 'Enter the subscription name where the Azure file share service has been created'
        if ($subnamelist -match $sub)
        {
            $subnameright = $true
        } else
        {
            $quitornotask = Read-Host 'The subscription name you input does not exist. [R]-retry,q-quit'
            if ($quitornotask -eq 'q')
            {
                Write-Host "Mounting Azure file share service quit." -ForegroundColor "Red"
                $quitornot = $true
            }
        }
    } while(!$submitright -and !$quitornot)
    
    if ($subnameright){
        Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
        $storageaccountlist = Get-AzureRmStorageAccount #Retrieve the storage account list
        echo $storageaccountlist
        $storageaccountnames = $storageaccountlist.StorageAccountName #get the storage account names
        $resourcegroupnames = $storageaccountlist.ResourceGroupName #get the resource group for storage accounts
        $goodsaname = $false
        $quitornot = $false
        while (!$goodsaname -and !$quitornot)
        {
            $sa = Read-Host "Enter the storage account name where the Azure file share you mount is created"
            if ($storageaccountnames -match $sa){
                $index = [array]::indexof($storageaccountnames,$sa)
                $rg = $resourcegroupnames[$index]
                $goodsaname = $true
            } else{
                $quitornotask = Read-Host "Storage account "$sa "does not exist under your subscription" $sub ". [R]-retry, Q-quit"
                if ($quitornotask.ToLower() -eq 'q')
                {
                    $quitornot = $true
                }
            }
        }
        if ($goodsaname){
            $storKey = (Get-AzureRmStorageAccountKey -Name $sa -ResourceGroupName $rg ).Key1
            $sharename = Read-Host 'Enter the name of the file share to mount'
            $drivename = Read-Host 'Enter the name of the drive. This name should be different from the disk names your virtual machine has.'

            # Save key securely
            cmdkey /add:$sa.file.core.windows.net /user:$sa /pass:$storKey

            # Mount the Azure file share as  drive letter on the VM. 
            net use $drivename \\$sa.file.core.windows.net\$sharename
        }
    }
}

if ($role -eq 3){
    
    $prompt = "Do you want to mount an Azure file share service to your Azure virtual machine? [Y]/N"
    
    $mountornot = Read-Host -Prompt $prompt
    if (!$mountornot -or $mountornot.ToLower() -eq 'y'){
        
        mountfileservices
        $others = $true
        DO{
            $prompt = "Do you want to mount other Azure file share services? [Y]/N"
            $mountornot = Read-Host -Prompt $prompt
            if (!$mountornot -or $mountornot.ToLower() -eq 'y'){
                mountfileservices
            } else{
                $others = $false
            }
        } while($others)
    }
}