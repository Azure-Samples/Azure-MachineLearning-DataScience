# Copy ProjectTemplate folder to GroupProjectTemplate folder
$src = "ProjectTemplate"
$dest = "GroupProjectTemplate"
$SourceDirectory = $PWD.Path+"\"+$src
$DestinationDirectory = $PWD.Path+"\"+$dest
$ExcludeSubDirectory = $SourceDirectory+'\.git'
$files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }

foreach ($file in $files)
{
	$CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
	Copy-Item $file.FullName -Destination $CopyPath
}

# Copy Utilities folder to GroupUtilities folder
$src = "Utilities"
$dest = "GroupUtilities"
$SourceDirectory = $PWD.Path+"\"+$src
$DestinationDirectory = $PWD.Path+"\"+$dest
$ExcludeSubDirectory = $SourceDirectory+'\.git'
$files = Get-ChildItem $SourceDirectory -Recurse | Where-Object { $ExcludeSubDirectory -notcontains $_.DirectoryName }

foreach ($file in $files)
{
	$CopyPath = Join-Path $DestinationDirectory $file.FullName.Substring($SourceDirectory.length)
	Copy-Item $file.FullName -Destination $CopyPath
}
