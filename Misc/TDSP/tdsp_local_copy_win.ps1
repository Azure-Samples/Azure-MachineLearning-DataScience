# Copy ProjectTemplate and Utilities folder to GroupProjectTemplate and GroupUtilities folder

function TDSP_local_copy {

$src = Read-Host -Prompt 'What is your source folder?'
$dest = Read-Host -Prompt 'What is your destination folder?'

$SourceDirectory = $PWD.Path+"\"+$src
$DestinationDirectory = $PWD.Path+"\"+$dest
$ExcludeSubDirectory = $SourceDirectory+'\.git'
$files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }

foreach ($file in $files)
{
	$CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
	Copy-Item $file.FullName -Destination $CopyPath
}
}

#ProjectTemplate --> GroupProjectTemplate
TDSP_local_copy
#Utilities --> GroupUtilities
TDSP_local_copy

