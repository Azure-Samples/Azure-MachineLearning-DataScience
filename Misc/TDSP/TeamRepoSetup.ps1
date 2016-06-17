$server = Read-Host -Prompt 'Input the VSTS server name'
$generalreponame = Read-Host -Prompt 'Input the name of the general repository'
$teamreponame  = Read-Host -Prompt 'Input the repo name of your team'
$rootdir = $PWD

$generalreponame = [uri]::EscapeDataString($generalreponame)
$teamreponame = [uri]::EscapeDataString($teamreponame)
$generalrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$generalreponame
$teamrepourl = 'https://'+$server+'.visualstudio.com/_git/'+$teamreponame

Write-host "URL of the general repository is "+$generalrepourl -ForegroundColor "Yellow"
Write-host "URL of the team repository is "+$teamrepourl -ForegroundColor "Yellow"

#$web_client = new-object System.Net.WebClient
#$gcmwurl = 'https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases/download/v1.4.0/GCMW-1.4.0.exe'

#function DownloadAndInstall($DownloadPath, $ArgsForInstall, $DownloadFileType = "exe")
#{
#    $LocalPath = [IO.Path]::GetTempFileName() + "." + $DownloadFileType
#    $web_client.DownloadFile($DownloadPath, $LocalPath)

#    Start-Process -FilePath $LocalPath -ArgumentList $ArgsForInstall -Wait
#}

Write-host "Installing Chocolatey. It is needed to install Git Credential Manager." -ForegroundColor "Yellow"
iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
Write-host "Chocolatey installed." -ForegroundColor "Green"

Write-host "Installing Git Credential manager..." -ForegroundColor "Yellow"
choco install git-credential-manager-for-windows -y
Write-host "Git Credential manager installed." -ForegroundColor "Green"

Write-host "Start cloning the general repository..." -ForegroundColor "Yellow"
Write-host "You might be asked to input your credentials..." -ForegroundColor "Yellow"
git clone $generalrepourl
Write-host "General repository cloned." -ForegroundColor "Green"

Write-host "Start cloning your team repository..." -ForegroundColor "Yellow"
Write-host "Currently it is empty. You need to determine the content of it..." -ForegroundColor "Yellow"
git clone $teamrepourl
Write-host "Team repository cloned." -ForegroundColor "Green"

Write-host "Copying the entire directory in "+$rootdir+"\"+$generalreponame+" except .git directory to "+$rootdir+"\"+$teamreponame+"..." -ForegroundColor "Yellow"
$SourceDirectory = $rootdir+"\"+$generalreponame
$DestinationDirectory = $rootdir+"\"+$teamreponame
$ExcludeSubDirectory = $SourceDirectory+'\.git'
$files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }

foreach ($file in $files)
{
    $CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
    Copy-Item $file.FullName -Destination $CopyPath
}

Write-host "General repository copied to the team repository on your disk." -ForegroundColor "Green"
Write-host "Change to the team repository directory "+$DestinationDirectory -ForegroundColor "Green"
cd $DestinationDirectory

$commitornot = Read-Host 'If you are ready to commit the new team repository, enter Y. Otherwise, go to change your team repository and come back to enter Y to commit...'

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
    Write-host "git config --global user.name <your name>" -ForegroundColor "Green"
    Write-host "git config --global user.email <your email address>" -ForegroundColor "Green"
    Write-host "git commit -m'This is a commit note'" -ForegroundColor "Green"
    Write-host "git push" -ForegroundColor "Green"
}









