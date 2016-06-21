$server = Read-Host -Prompt 'Input the VSTS server name'
$role = Read-Host -Prompt 'Select your role in your team:1-team lead;[2]-project lead;3-project team member'
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
Write-host $name1"cloned." -ForegroundColor "Green"

if ($role -lt 3){
    Write-host "Start cloning"$name2"..." -ForegroundColor "Yellow"
    Write-host "Currently it is empty. You need to determine the content of it..." -ForegroundColor "Yellow"
    git clone $teamrepourl
    Write-host $name2"cloned." -ForegroundColor "Green"
}

if ($role -lt 3)
{
    Write-host "Copying the entire directory in "$rootdir"\"$generalreponame"except .git directory to "$rootdir"\"$teamreponame"..." -ForegroundColor "Yellow"
    $SourceDirectory = $rootdir+"\"+$generalreponame
    $DestinationDirectory = $rootdir+"\"+$teamreponame
    $ExcludeSubDirectory = $SourceDirectory+'\.git'
    $files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }

    foreach ($file in $files)
    {
        $CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
        Copy-Item $file.FullName -Destination $CopyPath
    }

    Write-host $name1"copied to the "$name2" on your disk." -ForegroundColor "Green"
    Write-host "Change to the "$name2" directory "$DestinationDirectory -ForegroundColor "Green"
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
        Get-AzureSubscription | Format-Table
        # Select your subscription
        $sub = Read-Host 'Select the subscription name where resources will be created'
        $sa = Read-Host 'Enter the storage account name to create (has to be new)'
        $rg = Read-Host 'Enter the resource group to create (has to be new)'
        Get-AzureRmSubscription -SubscriptionName $sub | Select-AzureRmSubscription
        # Create a new resource group.
        New-AzureRmResourceGroup -Name $rg -Location 'South Central US'
        # Create a new storage account. You can reuse existing storage account if you wish.
        New-AzureRmStorageAccount -Name $sa -ResourceGroupName $rg -Location 'South Central US' -Type 'Standard_LRS'
        # Set your current working storage account
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

function mountfileservices
{
    # Authenticate to Azure.
    if ((Get-AzureRmSubscription).Length -le 0) {
        Login-AzureRmAccount
    }

    $sa = Read-Host 'Enter the storage account name where file share is created '
    $rg = Read-Host 'Enter the resource group '
    $storKey = (Get-AzureRmStorageAccountKey -Name $sa -ResourceGroupName $rg ).Key1

    # Get Azure File Service Share details
    $sharename = Read-Host 'Enter the name of the file share to mount'
    $drivename = Read-Host 'Enter the name of the drive. This name should be different from the disk names your virtual machine has.'

    # Save key securely
    cmdkey /add:$sa.file.core.windows.net /user:$sa /pass:$storKey

    # Mount the Azure file share as  drive letter on the VM. 
    net use $drivename \\$sa.file.core.windows.net\$sharename
}

if ($role -gt 1){
    
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
}