# Set-Location $AzCopy_path
# Specify your storage account name
$StorageAccountName = Read-Host -Prompt 'Input the storage account name'
# Specify your storage account key
$StorageAccountKey0 = Read-Host -Prompt 'Input the storage account key' -AsSecureString
$StorageAccountKey1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorageAccountKey0) 
$StorageAccountKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($StorageAccountKey1)

# Specify your storage account container name to store the NYC Taxi dataset
$ContainerName = Read-Host -Prompt 'Input the storage account container name to store the NYC Taxi dataset'
Write-Host "ContainerName: " $ContainerName
# The blob storage account destination 
$DestURL = "http://$StorageAccountName.blob.core.windows.net/$ContainerName"
Write-Host "DestURL: " $DestURL
	
# The NYC Taxi dataset on public blob
$Source = "http://getgoing.blob.core.windows.net/public/nyctaxidataset"

# Import data from your blob storage account to SQL DW
# Specify your server name
$Server = Read-Host -Prompt 'Input the SQL DW server name'
# Specify your SQL DW database name
$Database = Read-Host -Prompt 'Input the SQL DW database name'
# Specify your user name
$Username = Read-Host -Prompt 'Input the SQL DW user name'
# Specify your password
$pass0 = Read-Host -Prompt 'Input the password of user name which has the previlige to create the database' -AsSecureString
$pass1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass0) 
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($pass1)
	
$web_client = new-object System.Net.WebClient

function DownloadAndInstall($DownloadPath, $ArgsForInstall, $DownloadFileType = "exe")
{
    $LocalPath = [IO.Path]::GetTempFileName() + "." + $DownloadFileType
    $web_client.DownloadFile($DownloadPath, $LocalPath)

    Start-Process -FilePath $LocalPath -ArgumentList $ArgsForInstall -Wait
}

function InstallAzCopy(){
    Write-Output "Downloading and installing AzCopy now..." -ForegroundColor "Yellow"
	$download_url = "http://aka.ms/downloadazcopy"
    Write-host "Installing AzCopy..." -ForegroundColor "Yellow"
    DownloadAndInstall $download_url "" "msi"
}

function SearchAzCopy(){
    $AzCopy_list = Get-ChildItem -Path "C:\Program Files*\Microsoft SDKs\Azure\AzCopy" -Filter AzCopy.exe -Recurse -ErrorAction SilentlyContinue -Force | where {$_.FullName -like '*\AzCopy.exe'}

    if ($AzCopy_list -ne $null){
        $AzCopy_path = @('')*$AzCopy_list.count
        for ($i=0; $i -lt $AzCopy_list.count; $i++){
            $AzCopy_path[$i] = $AzCopy_list[$i].DirectoryName
        }
    }
    return $AzCopy_path
}

try 
{ 
    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
    #The SQL DW user and password is specified 
    $SQLConnection.ConnectionString = "Server=" + $Server + ";Database="+$Database+";User ID= "  + $Username + ";Password="  + $Password + ";" 
    $SQLConnection.Open() 
}
catch{
    Write-Host $Error[0] -ForegroundColor Red 
    exit 1 
}

#The GO switch is specified - parsing T-SQL code with GO
function ExecuteSQLFile($sqlfile,$go_or_not)
{ 
    if($go_or_not -eq 1) 
    { 
        $SQLCommandText = @(Get-Content -Path $sqlfile) 
        foreach($SQLString in  $SQLCommandText) 
        { 
            if($SQLString.ToLower() -ne "go") 
            { 
                #Preparation of SQL packet 
                if($SQLString.ToLower() -match "set @storageaccountname")
                {
                    $SQLPacket += "SET @StorageAccountName = '" + $StorageAccountName + "'`n"
                }
                Elseif($SQLString.ToLower() -match "set @storageaccountkey")
                {
                    $SQLPacket += "SET @StorageAccountKey = '" + $StorageAccountKey + "'`n"
                }
                Elseif($SQLString.ToLower() -match "set @containername")
                {
                    $SQLPacket += "SET @ContainerName = '" + $ContainerName + "'`n"
                }
                Else
                {
                    $SQLPacket += $SQLString + "`n"
                } 
            } 
            else 
            { 
                Write-Host "---------------------------------------------" 
                Write-Host "Executing SQL to load data into SQL DW:" 
                $IsSQLErr = $false 
                #Execution of SQL packet 
                try 
                { 
                    $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLPacket, $SQLConnection) 
                    $SQLCommand.CommandTimeout = 6000
                    $SQLCommand.ExecuteScalar() 
                } 
                catch 
                { 
 
                    $IsSQLErr = $true 
                    Write-Host $Error[0] -ForegroundColor Red 
                    $SQLPacket | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
                    $Error[0] | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
                    "----------" | Out-File -FilePath ($PWD.Path + "\SQLErrors.txt") -Append 
                } 
                if(-not $IsSQLErr) 
                { 
                    Write-Host "Execution succesful" 
                } 
                else 
                { 
                    Write-Host "Execution failed"  -ForegroundColor Red 
                } 
                $SQLPacket = "" 
            } 
        } 
    } 
    else 
    { 
        #Reading the T-SQL file as a whole packet 
        $SQLCommandText = @([IO.File]::ReadAllText($sqlfile)) 
        #Execution of SQL packet 
        try 
        { 
            $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLCommandText, $SQLConnection) 
            $SQLCommand.CommandTimeout = 0
            $SQLCommand.ExecuteScalar() 
        } 
        catch 
        { 
            Write-Host $Error[0] -ForegroundColor Red 
        } 
    } 
    #Disconnection from MS SQL Server 
    
    Write-Host "-----------------------------------------" 
    Write-Host $sqlfile "execution done"
}

try
{
    $AzCopy_path = SearchAzCopy
    if ($AzCopy_path -eq $null){
        Write-Host "AzCopy.exe is not found in C:\Program Files*. Now, start installing AzCopy..." -ForegroundColor "Yellow"
        InstallAzCopy
        $AzCopy_path = SearchAzCopy
    }
		$env_path = $env:Path
		for ($i=0; $i -lt $AzCopy_path.count; $i++){
			if ($AzCopy_path.count -eq 1){
				$AzCopy_path_i = $AzCopy_path
			} else {
				$AzCopy_path_i = $AzCopy_path[$i]
			}
			if ($env_path -notlike ‘*’+$AzCopy_path_i+'*'){
				Write-Host $AzCopy_path_i 'not in system path, add it...'
				[Environment]::SetEnvironmentVariable("Path", "$AzCopy_path_i;$env_path", "Machine")
				$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") 
				$env_path = $env:Path
			}
		}

    Write-Output "AzCopy is copying data from public blob to your storage account. It may take a while..." -ForegroundColor "Yellow"	
	$start_time = Get-Date
	AzCopy.exe /Source:$Source /Dest:$DestURL /DestKey:$StorageAccountKey /S
	$end_time = Get-Date
    $time_span = $end_time - $start_time
    $total_seconds = [math]::Round($time_span.TotalSeconds,2)
    Write-Output "AzCopy finished copying data. Please check your storage account to verify." -ForegroundColor "Yellow"
    Write-Host "This step (copying data from public blob to your storage account) takes $total_seconds seconds."

	$start_time = Get-Date
	ExecuteSQLFile LoadDataWithPolyBase.sql 1
	$end_time = Get-Date
    $time_span = $end_time - $start_time
    $total_seconds = [math]::Round($time_span.TotalSeconds,2)
    Write-Output "SQL script execution finished." -ForegroundColor "Yellow"
    Write-Host "This step (loading data from your private blob to SQLDW) takes $total_seconds seconds."

	
	$qa1 = "select count(*) from nyctaxi_trip"
	$qa2 = "select count(*) from nyctaxi_fare"
	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand($qa1, $SQLConnection) 
    $SQLCommand.CommandTimeout = 0
    $qa1_result = $SQLCommand.ExecuteScalar() 

	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand($qa2, $SQLConnection) 
    $SQLCommand.CommandTimeout = 0
    $SQLCommand.ExecuteScalar() 
	$qa2_result = $SQLCommand.ExecuteScalar()

	Write-Host "The numbers of records from taxi_trip and taxi_fare are " $qa1_result "and "  $qa2_result -ForegroundColor "Yellow"
	Write-Host "The data is loaded from your blob storage account to SQL DW." -ForegroundColor "Yellow"

	}
catch
{
    Write-Host "Error Message. " -ForegroundColor "Yellow"
}