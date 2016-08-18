# Copy ProjectTemplate and Utilities folder to GroupProjectTemplate and GroupUtilities folder

$role = Read-Host -Prompt 'Select your role in your team:1-group manager;[2]-team lead;3-project lead'

if ((!$role) -or (!($role -eq 1) -and !($role -eq 3))){
    $role = 2
}


function TDSP_local_copy ($reponame1, $reponame2) {
    
    $prompt1 = 'Please input the local path to '+$reponame1+' (source directory)'
    $prompt2 = 'Please input the local path to '+$reponame2+' (destination directory)'
    
    $validpath = $false
    while(!$validpath) {
        $src = Read-Host -Prompt $prompt1
        $src_git = $src+'\.git'
        if ((Test-Path $src) -and (Test-Path $src_git))
        {
            $validpath = $true
        } else{
            Write-Host $src 'is not a valid git repository. Please try it again.' -ForegroundColor Red
        }
    }

    $validpath = $false
    while(!$validpath) {
        $dest = Read-Host -Prompt $prompt2
        $dest_git = $dest+'\.git'
        if ((Test-Path $dest) -and (Test-Path $dest_git))
        {
            $validpath = $true
        } else{
            Write-Host $dest 'is not a valid git repository. Please try it again.' -ForegroundColor Red
        }
    }

    $ExcludeSubDirectory = $src+'\.git'
    $files = Get-ChildItem $src -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }
    Write-Host 'Start copying files (except files in .git directory) from '$src 'to'$dest'...' -ForegroundColor Yellow
    foreach ($file in $files)
    {
	    $CopyPath = Join-Path $dest $file.FullName.Substring($src.length)
	    Copy-Item $file.FullName -Destination $CopyPath
    }
}

if ($role -eq 1){
	$reponame1 = 'ProjectTemplate repository from Microsoft TDSP team'
	$reponame2 = 'Your GroupProjectTemplate repository'
	$reponame3 = 'Utilities repository from Microsoft TDSP team'
	$reponame4 = 'Your GroupUtilities repository'

	TDSP_local_copy($reponame1,$reponame2)
	TDSP_local_copy($reponame3,$reponame4)
}
elseif ($role -eq 2){
	$reponame1 = 'Your GroupProjectTemplate repository'
	$reponame2 = 'Your TeamProjectTemplate repository'
	$reponame3 = 'Your GroupUtilities repository'
	$reponame4 = 'Your TeampUtilities repository'

	TDSP_local_copy($reponame1,$reponame2)
	TDSP_local_copy($reponame3,$reponame4)
}
else{
	$reponame1 = 'Your TeamProjectTemplate repository'
	$reponame2 = 'Your Project repository'
	
	TDSP_local_copy($reponame1,$reponame2)
}
