# Copy ProjectTemplate and Utilities folder to GroupProjectTemplate and GroupUtilities folder

function TDSP_local_copy ($reponame1, $reponame2) {
    $prompt1 = 'Please input the local path to '+$reponame1+' (source directory)'
    $prompt2 = 'Please input the local path to '+$reponame2+' (source directory)'
    
    $validpath = $false
    while(!$validpath) {
        $src = Read-Host -Prompt $prompt1
        if (Test-Path $src)
        {
            $validpath = $true
        }
    }

    $validpath = $false
    while(!$validpath) {
        $dest = Read-Host -Prompt $prompt2
        if (Test-Path $dest)
        {
            $validpath = $true
        }
    }

    $ExcludeSubDirectory = $src+'\.git'
    $files = Get-ChildItem $src -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }
    Write-Host 'Start copying files (except files in .git directory) from '$src 'to'$dest'...' -ForegroundColor Yellow
    foreach ($file in $files)
    {
	    $CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
	    Copy-Item $file.FullName -Destination $CopyPath
    }
}

#ProjectTemplate --> GroupProjectTemplate
TDSP_local_copy 'ProjectTemplate repository from Microsoft TDSP team' 'Your GroupProjectTemplate repository'
#Utilities --> GroupUtilities
TDSP_local_copy 'Utilities repository from Microsoft TDSP team' 'Your GroupUtilities repository'

