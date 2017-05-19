<#-------------------------------------------------------------------------- 
.SYNOPSIS 
Script for  running T-SQL files in MS SQL Server 
Hang Zhang
Built on a post by Andy Mishechkin at https://gallery.technet.microsoft.com/scriptcenter/The-PowerShell-script-for-2a2456c4
This script has been tested on PowerShell V3, and not tested on older versions.
 
.DESCRIPTION 

.\RunSQL_SQL_Walkthrough.ps1

Users will be prompted to input parameters for:
- name of Microsoft SQL Server with R Service instance  
- database name that you want to create and use in this walkthrough 
- path and name of the .csv file on the local machine to be loaded to the database 
- user name which has the previliges of creating database, tables, stored procedures, and uploading data to tables
- password of users
 
Examples. 
 
Execute on remote SQL Server Express with   
.\RunSQL_SQL_Walkthrough.ps1
 
---------------------------------------------------------------------------#> 

function DownloadAndInstall($DownloadPath, $ArgsForInstall, $DownloadFileType = "exe")
{
    $LocalPath = [IO.Path]::GetTempFileName() + "." + $DownloadFileType
    $web_client.DownloadFile($DownloadPath, $LocalPath)

    Start-Process -FilePath $LocalPath -ArgumentList $ArgsForInstall -Wait
}

function InstallSQLUtilities(){
    # Install SQL Server Command Line Utilities
    $b = Get-WmiObject -Class Win32_Product | sort-object Name | select Name | where { $_.Name -match “Microsoft SQL Server" -and $_.Name -match "Command Line Utilities" }
    if($b -eq $null)
    {
        Write-Output "SQL Server Command Line Utilities not installed. Download and install SQL Server Command Line Utilities" -ForegroundColor "Yellow"
        $os = Get-WMIObject win32_operatingsystem
        $os_bit = $os.OSArchitecture
        if($os_bit -eq '64-bit')
        {
            $download_url1 = "http://go.microsoft.com/fwlink/?LinkID=188401&clcid=0x409"
            $download_url2 = "http://go.microsoft.com/fwlink/?LinkID=188430&clcid=0x409"
        }
        else
        {
            $download_url1 = "http://go.microsoft.com/fwlink/?LinkID=188400&clcid=0x409"
            $download_url2 = "http://go.microsoft.com/fwlink/?LinkID=188429&clcid=0x409"
        }
        Write-host "Installing SQL Server Native Client..." -ForegroundColor "Yellow"
        DownloadAndInstall $download_url1 "/quiet IACCEPTSQLNCLILICENSETERMS=YES" "msi"
        Write-host "Installing SQL Command Line Utilities..." -ForegroundColor "Yellow"
        DownloadAndInstall $download_url2 "/quiet" "msi"
    }
}

function SearchBCP(){
    $bcp_list = Get-ChildItem -Path "C:\Program Files*\" -Filter bcp.exe -Recurse -ErrorAction SilentlyContinue -Force | where {$_.FullName -like '*\bcp.exe'}

    if ($bcp_list -ne $null){
        $bcp_path = @('')*$bcp_list.count
        for ($i=0; $i -lt $bcp_list.count; $i++){
            $bcp_path[$i] = $bcp_list[$i].DirectoryName
        }
    }
    return $bcp_path
}

function ExecuteSQLFile($sqlfile,$go_or_not)
{ 
    if($go_or_not -eq 1) 
    { 
        $SQLCommandText = @(Get-Content -Path $sqlfile) 
        foreach($SQLString in  $SQLCommandText) 
        { 
            if($SQLString -ne "go") 
            { 
                #Preparation of SQL packet 
                if($SQLString -match "SET @path_to_data")
                {
                    $SQLPacket += "SET @path_to_data = '" + $csvfilepath + "'`n"
                }
                Elseif($SQLString.ToLower() -match "set @db_name")
                {
                    $SQLPacket += "set @db_name = '" + $dbname + "'`n"
                }
                Elseif($SQLString -match "SET @db_name")
                {
                    $SQLPacket += "SET @db_name = " + $dbname + "`n"
                }
                Elseif($SQLString.ToLower() -match "use \[taxinyc_sample")
                {
                    $SQLPacket += "USE [" + $dbname +"]`n"
                }
                Else
                {
                    $SQLPacket += $SQLString + "`n"
                } 
            } 
            else 
            { 
                Write-Host "---------------------------------------------" 
                Write-Host "Executed SQL packet:" 
                Write-Host $SQLPacket 
                $IsSQLErr = $false 
                #Execution of SQL packet 
                try 
                { 
                    $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLPacket, $SQLConnection) 
                    $SQLCommand.CommandTimeout = 0
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

###################### End of Functions / Start of Script ######################

$server = Read-Host -Prompt 'Input the database server name (the full address)'
$dbname = Read-Host -Prompt 'Input the name of the database you want to create'
$u = Read-Host -Prompt 'Input the user name which has the previlige to create the database'
$p0 = Read-Host -Prompt 'Input the password of user name which has the previlige to create the database' -AsSecureString
$p1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($p0)
$p = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($p1)
$csvfilepath = Read-Host -Prompt 'Input the path to the csv file you want to upload to the database'

# Check whether BCP is intalled on the computer. If no, install it.
$web_client = new-object System.Net.WebClient
try
{
    $bcp_path = SearchBCP
    if ($bcp_path -eq $null){
        Write-Host "bcp.exe is not found in C:\Program Files*. Now, start installing SQL Utilities..." -ForegroundColor "Yellow"
        InstallSQLUtilities
        $bcp_path = SearchBCP
    }
    Write-Host "Adding path to bcp.exe to the system path..." -Foregroundcolor "Yellow"
    $env_path = $env:Path
    for ($i=0; $i -lt $bcp_path.count; $i++){
        if ($bcp_path.count -eq 1){
            $bcp_path_i = $bcp_path
        } else {
            $bcp_path_i = $bcp_path[$i]
        }
        if ($env_path -notlike ‘*’+$bcp_path_i+'*'){
            Write-Host $bcp_path_i 'not in system path, add it...'
            [Environment]::SetEnvironmentVariable("Path", "$bcp_path_i;$env_path", "Machine")
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") 
            $env_path = $env:Path
        }
    }
}
catch
{
    Write-Host "Installing SQL Utilities failed. "
}

#Connect to MS SQL Server 
try 
{ 
    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
    #The MS SQL Server user and password is specified 
    if($u -and $p) 
    { 
        $SQLConnection.ConnectionString = "Server=" + $server + ";Database=master;User ID= "  + $u + ";Password="  + $p + ";" 
    } 
    #The MS SQL Server user and password is not specified - using the Windows user credentials 
    else 
    { 
        $SQLConnection.ConnectionString = "Server=" + $server + ";Database=master;Integrated Security=True" 
    } 
    $SQLConnection.Open() 
} 
#Error of connection 
catch 
{ 
    Write-Host $Error[0] -ForegroundColor Red 
    exit 1 
} 

# Create database and tables, and upload data to database from local machine using BCP
Write-Host "Start creating database and table on your SQL Server, and uploading data to the table. It may take a while..."
$start_time = Get-Date
try
{
    ExecuteSQLFile $PWD"\create-db-tb-upload-data.sql" 1
}
catch
{
    Write-Host "Creating database and tables failed. Probably the database or tables already exist." -ForegroundColor "Red"
}

$db_tb = $dbname + ".dbo.nyctaxi_sample"
Write-host "start loading the data to SQL Server table..." -Foregroundcolor "Yellow"
try
{
	if($u -and $p)
	{
    bcp $db_tb in $csvfilepath -t ',' -S $server -f taxiimportfmt.xml -F 2 -C "RAW" -b 200000 -U $u -P $p
	}
	#The MS SQL Server user and password is not specified - using the Windows user credentials 
	else 
	{
	bcp $db_tb in $csvfilepath -t ',' -S $server -f taxiimportfmt.xml -F 2 -C "RAW" -b 200000 -T
	}
}
catch
{
    Write-Host "BCP uploading data to table failed. Please check whether bcp.exe is installed and the path is added to system path." -ForegroundColor "Red"
}
$end_time = Get-Date
$time_span = $end_time - $start_time
$total_seconds = [math]::Round($time_span.TotalSeconds,2)
Write-Host "This step (creating database and tables, and uploading data to table) takes $total_seconds seconds." -Foregroundcolor "Yellow"

Write-Host "Start running the .sql files to register all functions and stored procedures used in this walkthrough..."
$start_time = Get-Date

ExecuteSQLFile $PWD"\fnCalculateDistance.sql" 1
ExecuteSQLFile $PWD"\fnEngineerFeatures.sql" 1
ExecuteSQLFile $PWD"\TrainingTestingSplit.sql" 1
ExecuteSQLFile $PWD"\TrainTipPredictionModelSciKitPy.sql" 1
ExecuteSQLFile $PWD"\TrainTipPredictionModelRxPy.sql" 1
ExecuteSQLFile $PWD"\SerializePlots.sql" 1
ExecuteSQLFile $PWD"\PredictTipSciKitPy.sql" 1
ExecuteSQLFile $PWD"\PredictTipSingleModeSciKitPy.sql" 1
ExecuteSQLFile $PWD"\PredictTipRxPy.sql" 1
ExecuteSQLFile $PWD"\PredictTipSingleModeRxPy.sql" 1
Write-Host "Completed registering all functions and stored procedures used in this walkthrough."
$end_time = Get-Date
$time_span = $end_time - $start_time
$total_seconds = [math]::Round($time_span.TotalSeconds,2)
Write-Host "This step (registering all functions and stored procedures) takes $total_seconds seconds."
$SQLConnection.Close()
