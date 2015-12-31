function ReadHostInput(){
    $Script:StorageAccountName = Read-Host -Prompt 'Input the storage account name'
    $StorageAccountKey0 = Read-Host -Prompt 'Input the storage account key' -AsSecureString
    $StorageAccountKey1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($StorageAccountKey0) 
    $Script:StorageAccountKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($StorageAccountKey1)
    $ContainerName0 = Read-Host -Prompt 'Input your storage account container name to upload the NYC Taxi dataset to. Only letters, numbers, and the dash (-) character'
    $Script:Server = Read-Host -Prompt 'Input the SQL DW server name'
    $Script:Database = Read-Host -Prompt 'Input the SQL DW database name'
    $Script:Username = Read-Host -Prompt 'Input the SQL DW user name'
    $pass0 = Read-Host -Prompt 'Input the password of user name which has the previlege to create the database' -AsSecureString
    $pass1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass0) 
    $Script:Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($pass1)

	$Script:RandomNumber = Get-Random -minimum 100 -maximum 999

	#Intermediate resources 
	$Script:KeyAlias = 'KeyAlias' + '_' + $RandomNumber
    $Script:ContainerName = $ContainerName0 + '-' + $RandomNumber
    $Script:nyctaxi_trip_storage = 'nyctaxi_trip_storage' + '_' + $RandomNumber
	$Script:nyctaxi_fare_storage = 'nyctaxi_fare_storage' + '_' + $RandomNumber
	$Script:csv_file_format = 'csv_file_format' + '_' + $RandomNumber
	$Script:external_nyctaxi_trip = 'external_nyctaxi_trip' + '_' + $RandomNumber
	$Script:external_nyctaxi_fare = 'external_nyctaxi_fare' + '_' + $RandomNumber

	#Specify your schema and table names
	$Script:SchemaName = Read-Host -Prompt 'Input the schema name for your NYC Taxi data to avoid conflict with other users of the same SQL Data Warehouse' 

	#if(($Script:SchemaName = Read-Host "Input the schema name for your NYC Taxi data[nyctaxischema]") -eq ''){
    #    $Script:SchemaName = "nyctaxischema"
    #    Write-Host "Taking default schema $SchemaName for NYC Taxi Trip table." -ForegroundColor "Yellow"
    #}
	
	if(($Script:TripTableName = Read-Host "Input the NYC Taxi Trip table name[nyctaxitrip]") -eq ''){
        $Script:TripTableName = "nyctaxitrip"
        Write-Host "Taking default name $TripTableName for NYC Taxi Trip table." -ForegroundColor "Yellow"
    }
	if(($Script:FareTableName = Read-Host "Input the NYC Taxi Fare table name[nyctaxifare]") -eq ''){
        $Script:FareTableName = "nyctaxifare"
        Write-Host "Taking default name $FareTableName for NYC Taxi Fare table." -ForegroundColor "Yellow"
    }
	if(($Script:SampleTableName = Read-Host "Input the NYC Taxi Sample table name[nyctaxisample]") -eq ''){
        $Script:SampleTableName = "nyctaxisample"
        Write-Host "Taking default name $SampleTableName for NYC Taxi Sample table." -ForegroundColor "Yellow"
    }

	Write-host "The tables created in your SQL DW are $SchemaName.$TripTableName , $SchemaName.$FareTableName and $SchemaName.$SampleTableName. " -ForegroundColor "Yellow"

}


function ReadConfFile(){
    $ConfContent = @(Get-Content -Path $conf_file) 
    foreach($ConfLine in  $ConfContent) 
    {
        $ConfLine1 = $ConfLine.split(':')
        $ParmName = $ConfLine1[0].Trim()
        $ParmValue = $ConfLine1[1].Trim()
        switch($ParmName)
        {
            "StorageAccountName" {$Script:StorageAccountName = $ParmValue}
            "StorageAccountKey" {$Script:StorageAccountKey = $ParmValue}
            "ContainerName" {$Script:ContainerName = $ParmValue}
            "Server" {$Script:Server = $ParmValue}
            "Database" {$Script:Database = $ParmValue}
            "Username" {$Script:Username = $ParmValue}
            "Password" {$Script:Password = $ParmValue}
			"SchemaName" {$Script:SchemaName = $ParmValue}
			"TripTableName" {$Script:TripTableName = $ParmValue}
            "FareTableName" {$Script:FareTableName = $ParmValue}
			"SampleTableName" {$Script:SampleTableName = $ParmValue}

        }
    }
    return $ContainerName, $TripTableName, $FareTableName, $SampleTableName, $SchemaName

}

	
function WriteConfFile(){
  $file = @(
            "StorageAccountName : $StorageAccountName",
            "StorageAccountKey : $StorageAccountKey",
            "ContainerName : $ContainerName",
            "Server : $Server",
            "Database : $Database",
            "Username : $Username",
            "Password : $Password",
			"SchemaName : $SchemaName",
			"TripTableName : $TripTableName",
			"FareTableName : $FareTableName",
			"SampleTableName : $SampleTableName"
        )
  $file | Out-File $conf_file -Encoding UTF8 -Force
}

function Generate_new_names($OldString, $New_RandomNumber,$Delimiter){
    $OldRN = $OldString.Split($Delimiter)[-1]
    try{
        $OldRN_Int = $OldRN -as [int]
        if ($OldRN_Int -ge 100 -and $OldRN -le 999){
            $NewString = $OldString -replace $OldRN, $New_RandomNumber
        } else{
            $NewString = $OldString + '_' + $New_RandomNumber
            Write-Host "Old table name $OldString does not end with random number between 100 and 999. The new table name with random number is $NewString." -ForegroundColor "Yellow"
        }
    } catch{
        $NewString = $OldString + '_' + $New_RandomNumber
        Write-Host "Old table name $OldString does not end with random number between 100 and 999. The new table name with random number is $NewString." -ForegroundColor "Yellow"
    }
    return $NewString
}

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
    DownloadAndInstall $download_url "/quiet" "msi"
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
                    #Write-host "$StorageAccountName"
                }
                Elseif($SQLString.ToLower() -match "set @storageaccountkey")
                {
                    $SQLPacket += "SET @StorageAccountKey = '" + $StorageAccountKey + "'`n"
                    #Write-host "$StorageAccountKey"
                }
                Elseif($SQLString.ToLower() -match "set @containername")
                {
                    $SQLPacket += "SET @ContainerName = '" + $ContainerName + "'`n"
                    #Write-host "$ContainerName"
                }
				Elseif($SQLString.ToLower() -match "set @keyalias")
				{
				    $SQLPacket += "SET @KeyAlias = '" + $KeyAlias + "'`n"
                    #Write-host "$KeyAlias"
				}
				Elseif($SQLString.ToLower() -match "set @nyctaxi_trip_storage")
				{
				    $SQLPacket += "SET @nyctaxi_trip_storage = '" + $nyctaxi_trip_storage + "'`n"
                    #Write-host "$nyctaxi_trip_storage"
				}
				Elseif($SQLString.ToLower() -match "set @nyctaxi_fare_storage")
				{
				    $SQLPacket += "SET @nyctaxi_fare_storage = '" + $nyctaxi_fare_storage + "'`n"
                    #Write-host "$nyctaxi_fare_storage"
				}
				Elseif($SQLString.ToLower() -match "set @external_nyctaxi_trip")
				{
				    $SQLPacket += "SET @external_nyctaxi_trip = '" + $external_nyctaxi_trip + "'`n"
                    #Write-host "$external_nyctaxi_trip"
				}
				Elseif($SQLString.ToLower() -match "set @external_nyctaxi_fare")
				{
				    $SQLPacket += "SET @external_nyctaxi_fare = '" + $external_nyctaxi_fare + "'`n"
                    #Write-host "$external_nyctaxi_fare"
				}	
				Elseif($SQLString.ToLower() -match "set @schemaname")
				{
				    $SQLPacket += "SET @schemaname = '" + $SchemaName + "'`n"
                    #Write-host "$SchemaName"
				}				
				Elseif($SQLString.ToLower() -match "set @nyctaxi_trip")
				{
				    $SQLPacket += "SET @nyctaxi_trip = '" + $TripTableName + "'`n"
                    #Write-host "$TripTableName"
				}
				Elseif($SQLString.ToLower() -match "set @nyctaxi_fare")
				{
				    $SQLPacket += "SET @nyctaxi_fare = '" + $FareTableName + "'`n"
                    #Write-host "$FareTableName"
				}
				Elseif($SQLString.ToLower() -match "set @nyctaxi_sample")
				{
				    $SQLPacket += "SET @nyctaxi_sample = '" + $SampleTableName + "'`n"
                    #Write-host "$SampleTableName"
				}				
				Elseif($SQLString.ToLower() -match "set @csv_file_format")
				{
				    $SQLPacket += "SET @csv_file_format = '" + $csv_file_format + "'`n"
                    #Write-host "$csv_file_format"
				}	

                Else
                {
                    $SQLPacket += $SQLString + "`n"
                }
                #Write-Host $SQLPacket 
            } 
            else 
            { 
                Write-Host "---------------------------------------------" 
                Write-Host "Executing SQL to load data into SQL DW:" 
				#Write-Host $SQLPacket
                $IsSQLErr = $false 
                #Execution of SQL packet 
                try 
                { 
                    $SQLCommand = New-Object System.Data.SqlClient.SqlCommand($SQLPacket, $SQLConnection) 
                    $SQLCommand.CommandTimeout = 6000
			        #$SQLCommand.CommandTimeout = 0
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
                    Write-Host "Execution successful" 
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
            $SQLCommand.CommandTimeout = 6000
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



#-------------------------------------------------------------------#
# Main code starts from here
#-------------------------------------------------------------------#
# Specify your storage account name
$conf_file = "$PWD\SQLDW.conf"
$StorageAccountName = ""
$StorageAccountKey = ""
$ContainerName = ""
$Server = ""
$Database = ""
$Username = ""
$Password = ""
$KeyAlias = ""
$nyctaxi_trip_storage = ""
$nyctaxi_fare_storage = ""
$external_nyctaxi_fare = ""
$external_nyctaxi_trip = ""
$csv_file_format = ""
$SchemaName = ""
$TripTableName = ""
$FareTableName = ""
$SampleTableName = ""

If (Test-Path $conf_file){
  $yesorno = Read-Host -Prompt "Configuration file $conf_file found. Do you want to use the parameters there?[Y]/N"
  if ($yesorno -eq "" -Or $yesorno.ToLower() -eq 'y'){
    Write-Host "Reading parameters from configuration file $conf_file..." -ForegroundColor "Yellow"
    $ConfResults = ReadConfFile
    $New_RandomNumber = get-random -minimum 100 -maximum 999
    #$ContainerName = Generate_new_names $ConfResults[0] $New_RandomNumber '-'
    $KeyAlias = 'KeyAlias' + '_' + $New_RandomNumber
    $nyctaxi_trip_storage = 'nyctaxi_trip_storage' + '_' + $New_RandomNumber
    $nyctaxi_fare_storage = 'nyctaxi_fare_storage' + '_' + $New_RandomNumber
    $external_nyctaxi_fare = 'external_nyctaxi_fare' + '_' + $New_RandomNumber
    $external_nyctaxi_trip = 'external_nyctaxi_trip' + '_' + $New_RandomNumber
    $csv_file_format = 'csv_file_format' + '_' + $New_RandomNumber
    $TripTableName = $ConfResults[1]
	$FareTableName = $ConfResults[2]
	$SampleTableName = $ConfResults[3]
    $SchemaName0 = Generate_new_names $ConfResults[4] $New_RandomNumber '_'
    $SchemaName = Read-Host -Prompt "Please input a new schema name [$SchemaName0]"
    if ($SchemaName -eq ""){
        $SchemaName = $SchemaName0
    }
    Write-host "The tables created in your SQL DW are $SchemaName.$TripTableName , $SchemaName.$FareTableName and $SchemaName.$SampleTableName. " -ForegroundColor "Yellow"
    Write-Host "Overwriting existing configuration file $conf_file..." -ForegroundColor "Yellow"
    WriteConfFile
    
  } else{
    ReadHostInput
    $yesorno = Read-Host -Prompt "Overwrite existing configuration file $conf_file?[Y]/N"
    if ($yesorno -eq "" -Or $yesorno.ToLower() -eq 'y'){
        Write-Host "Overwriting existing configuration file $conf_file..." -ForegroundColor "Yellow"
        WriteConfFile
    }
  }
}Else{
  ReadHostInput
  WriteConfFile
}

$DestURL = "http://$StorageAccountName.blob.core.windows.net/$ContainerName"
#Write-Host "DestURL: " $DestURL	
# The NYC Taxi dataset on public blob
$Source = "http://getgoing.blob.core.windows.net/public/nyctaxidataset"
	
$web_client = new-object System.Net.WebClient

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
			if ($env_path -notlike '*' +$AzCopy_path_i+'*'){
				Write-Host $AzCopy_path_i 'not in system path, add it...'
				[Environment]::SetEnvironmentVariable("Path", "$AzCopy_path_i;$env_path", "Machine")
				$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") 
				$env_path = $env:Path
			}
		}

    Write-Host "AzCopy is copying data from public blob to your storage account. It may take a while..." -ForegroundColor "Yellow"	
	$start_time = Get-Date
	AzCopy.exe /Source:$Source /Dest:$DestURL /DestKey:$StorageAccountKey /S
	$end_time = Get-Date
    $time_span = $end_time - $start_time
    $total_seconds = [math]::Round($time_span.TotalSeconds,2)
    Write-Host "AzCopy finished copying data. Please check your storage account to verify." -ForegroundColor "Yellow"
    Write-Host "This step (copying data from public blob to your storage account) takes $total_seconds seconds." -ForegroundColor "Green"

	$start_time = Get-Date
	ExecuteSQLFile LoadDataToSQLDW.sql 1
	$end_time = Get-Date
    $time_span = $end_time - $start_time
    $total_seconds = [math]::Round($time_span.TotalSeconds,2)
    Write-Host "SQL script execution finished." -ForegroundColor "Yellow"
    Write-Host "This step (loading data from your private blob to SQLDW) takes $total_seconds seconds." -ForegroundColor "Green"

	
	$qa1 = "select count(*) from $SchemaName.$TripTableName"
	$qa2 = "select count(*) from $SchemaName.$FareTableName"
	$qa3 = "select count(*) from $SchemaName.$SampleTableName"

	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand($qa1, $SQLConnection) 
    $SQLCommand.CommandTimeout = 0
    $qa1_result = $SQLCommand.ExecuteScalar() 

	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand($qa2, $SQLConnection) 
    $SQLCommand.CommandTimeout = 0
	$qa2_result = $SQLCommand.ExecuteScalar()

	$SQLCommand = New-Object System.Data.SqlClient.SqlCommand($qa3, $SQLConnection) 
    $SQLCommand.CommandTimeout = 0
	$qa3_result = $SQLCommand.ExecuteScalar()


	Write-Host "The numbers of records from $TripTableName, $FareTableName,$SampleTableName  are  $qa1_result, $qa2_result, and $qa3_result" -ForegroundColor "Yellow"
	Write-Host "The data is loaded from your blob storage account to SQL DW." -ForegroundColor "Green"


    Write-Host "Plug in the parameterized table names in SQL script file" -Foregroundcolor "Yellow"
    $start_time = Get-Date
    if($PSVersionTable.WSManStackVersion.Major -ge 3)
    {
        (gc ./SQLDW_Explorations.sql).replace('<nyctaxi_trip>', "$SchemaName.$TripTableName") | sc ./SQLDW_Explorations.sql
        (gc ./SQLDW_Explorations.sql).replace('<nyctaxi_fare>', "$SchemaName.$FareTableName") | sc ./SQLDW_Explorations.sql
        (gc ./SQLDW_Explorations.sql).replace('<nyctaxi_sample>', "$SchemaName.$SampleTableName") | sc ./SQLDW_Explorations.sql


        (gc ./SQLDW_Explorations.ipynb).replace('<nyctaxi_trip>', "$SchemaName.$TripTableName") | sc ./SQLDW_Explorations.ipynb
        (gc ./SQLDW_Explorations.ipynb).replace('<nyctaxi_fare>', "$SchemaName.$FareTableName") | sc ./SQLDW_Explorations.ipynb
        (gc ./SQLDW_Explorations.ipynb).replace('<nyctaxi_sample>', "$SchemaName.$SampleTableName") | sc ./SQLDW_Explorations.ipynb

        (gc ./SQLDW_Explorations.ipynb).replace('<server name>', $Server) | sc ./SQLDW_Explorations.ipynb
        (gc ./SQLDW_Explorations.ipynb).replace('<database name>', $Database) | sc ./SQLDW_Explorations.ipynb
        (gc ./SQLDW_Explorations.ipynb).replace('<user name>', $Username) | sc ./SQLDW_Explorations.ipynb
        (gc ./SQLDW_Explorations.ipynb).replace('<password>', $Password) | sc ./SQLDW_Explorations.ipynb
        (gc ./SQLDW_Explorations.ipynb).replace('<database server>', 'SQL Server Native Client 11.0') | sc ./SQLDW_Explorations.ipynb

        (gc ./SQLDW_Explorations_Scripts.py).replace('<nyctaxi_trip>', "$SchemaName.$TripTableName") | sc ./SQLDW_Explorations_Scripts.py
        (gc ./SQLDW_Explorations_Scripts.py).replace('<nyctaxi_fare>', "$SchemaName.$FareTableName") | sc ./SQLDW_Explorations_Scripts.py
        (gc ./SQLDW_Explorations_Scripts.py).replace('<nyctaxi_sample>', "$SchemaName.$SampleTableName") | sc ./SQLDW_Explorations_Scripts.py

        (gc ./SQLDW_Explorations_Scripts.py).replace('<server name>', $Server) | sc ./SQLDW_Explorations_Scripts.py
        (gc ./SQLDW_Explorations_Scripts.py).replace('<database name>', $Database) | sc ./SQLDW_Explorations_Scripts.py
        (gc ./SQLDW_Explorations_Scripts.py).replace('<user name>', $Username) | sc ./SQLDW_Explorations_Scripts.py
        (gc ./SQLDW_Explorations_Scripts.py).replace('<password>', $Password) | sc ./SQLDW_Explorations_Scripts.py
        (gc ./SQLDW_Explorations_Scripts.py).replace('<database driver>', 'SQL Server Native Client 11.0') | sc ./SQLDW_Explorations_Scripts.py
    }
    else
    {

        (gc ./SQLDW_Explorations.sql) -replace '<nyctaxi_trip>', "$SchemaName.$TripTableName"
        (gc ./SQLDW_Explorations.sql) -replace '<nyctaxi_fare>', "$SchemaName.$FareTableName"
        (gc ./SQLDW_Explorations.sql) -replace '<nyctaxi_sample>', "$SchemaName.$SampleTableName"

        (gc ./SQLDW_Explorations.ipynb) -replace '<nyctaxi_trip>', "$SchemaName.$TripTableName"
        (gc ./SQLDW_Explorations.ipynb) -replace '<nyctaxi_fare>', "$SchemaName.$FareTableName"
        (gc ./SQLDW_Explorations.ipynb) -replace '<nyctaxi_sample>', "$SchemaName.$SampleTableName"
		
		(gc ./SQLDW_Explorations.ipynb) -replace '<server name>', $Server
        (gc ./SQLDW_Explorations.ipynb) -replace '<database name>', $Database
        (gc ./SQLDW_Explorations.ipynb) -replace '<user name>', $Username
        (gc ./SQLDW_Explorations.ipynb) -replace '<password>', $Password
        (gc ./SQLDW_Explorations.ipynb) -replace '<database server>', 'SQL Server Native Client 11.0'

        (gc ./SQLDW_Explorations_Scripts.py) -replace '<nyctaxi_trip>', "$SchemaName.$TripTableName"
        (gc ./SQLDW_Explorations_Scripts.py) -replace '<nyctaxi_fare>', "$SchemaName.$FareTableName"
        (gc ./SQLDW_Explorations_Scripts.py) -replace '<nyctaxi_sample>', "$SchemaName.$SampleTableName"
		
		(gc ./SQLDW_Explorations_Scripts.py) -replace '<server name>', $Server
        (gc ./SQLDW_Explorations_Scripts.py) -replace '<database name>', $Database
        (gc ./SQLDW_Explorations_Scripts.py) -replace '<user name>', $Username
        (gc ./SQLDW_Explorations_Scripts.py) -replace '<password>', $Password
        (gc ./SQLDW_Explorations_Scripts.py) -replace '<database driver>', 'SQL Server Native Client 11.0'
    }

    $end_time = Get-Date
    $time_span = $end_time - $start_time
    $total_seconds = [math]::Round($time_span.TotalSeconds,2)
    Write-Host "This step (plugging in database information) takes $total_seconds seconds." -Foregroundcolor "Yellow"

    
	$DeleteTable_file = "$PWD\DeleteResourcesOnSQLDW.sql"
	$DeleteTableSqlScript = "
	DROP EXTERNAL TABLE $external_nyctaxi_fare
	DROP EXTERNAL TABLE $external_nyctaxi_trip

	DROP EXTERNAL DATA SOURCE $nyctaxi_trip_storage
	DROP EXTERNAL DATA SOURCE $nyctaxi_fare_storage
	DROP EXTERNAL FILE FORMAT $csv_file_format
	DROP DATABASE SCOPED CREDENTIAL $KeyAlias
	
	"
	Out-File $DeleteTable_file -inputobject $DeleteTableSqlScript  -Encoding UTF8 -Force


	##If you want to drop the temporary tables you created, please execute the following line:
	$start_time = Get-Date
	ExecuteSQLFile $DeleteTable_file 0
	$end_time = Get-Date
    $time_span = $end_time - $start_time
    $total_seconds = [math]::Round($time_span.TotalSeconds,2)
    Write-Host "Deleting intermediate resources finished." -ForegroundColor "Yellow"
    Write-Host "This step (deleting intermediate resources) takes $total_seconds seconds." -ForegroundColor "Green"
}
catch
{
    Write-Host "Error Message. " -ForegroundColor "Yellow"
}