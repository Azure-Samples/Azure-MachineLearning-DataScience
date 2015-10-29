param([string]$dest = "C:\temp\nyctaxi1pct.csv")
$source = 'http://getgoing.blob.core.windows.net/public/nyctaxi1pct.csv'
$wc = New-Object System.Net.WebClient
$dest_dir = split-path $dest
if(!(Test-Path -Path $dest_dir )){
    Write-Host "Directory $dest_dir  does not exist. Create it."
    New-Item -ItemType directory -Path $dest_dir
}
Write-Host "Start downloading $source  to  $dest..."
$start_time = Get-Date
$wc.DownloadFile($source, $dest)
$end_time = Get-Date
$time_span = $end_time - $start_time
$total_seconds = [math]::Round($time_span.TotalSeconds,2)
Write-Host "Downloading completed. It takes $total_seconds seconds."
