<#-------------------------------------------------------------------------- 
.SYNOPSIS 
Script for  running T-SQL files in MS SQL Server 
Andy Mishechkin 
 
.DESCRIPTION 
runsql.ps1 has a next command prompt format: 
.\runsql.ps1 -server MSSQLServerInstance -dbname 
ExecContextDB -file MyTSQL.sql [-go] [-u SQLUser] [-p SQLPassword] 
 
Mandatory parameters: 
-server - name of Microsoft SQL Server instance  
-dbname - database name for  T-SQL execution context (use the '-dbname master' for  creation of new database) 
-file - name of .sql file, which contain T-SQL code for  execution 
 
Optional parameters: 
-go - parameter-switch, which must be, if  T-SQL code is contains 'GO'  statements. If you will use the -go switch for T-SQL script, which is not contains 'GO'-statements - this  script will not execute 
-u - the user name if  using Microsoft SQL Server authentication 
-p - the password  if  using Microsoft SQL Server authentication 
 
Examples. 
 
1) Execute on local SQL Server the script CreateDB.sql, which is placed in  C:\MyTSQLScripts\ and contains 'GO'  statements, using 
 
Windows credentials of current user: 
.\runsql.ps1 -server local -dbname master -file C:\MyTSQLScripts\CreateDB.sql -go 
 
2) Execute on remote SQL Server Express with   
machine name 'SQLSrvr'  the script CreateDB.sql, which is placed in C:\MyTSQLScripts\ and  
contains 'GO' statements, using SQL Server user name 'sa' and password 'S@Passw0rd': 
.\runsql.ps1 -server SQLSrvr\SQLEXPRESS -dbname master -file C:\MyTSQLScripts\CreateDB.sql -go -u sa -p S@Passw0rd 
 
---------------------------------------------------------------------------#> 
#Script parameters 
param( 
        #Name of MS SQL Server instance 
        [parameter(Mandatory=$true, 
               HelpMessage="Specify the SQL Server name where will be run a T-SQL code",Position=0)] 
        [String] 
        [ValidateNotNullOrEmpty()] 
        $server = $(throw "sqlserver parameter is required."), 
 
        #Database name for execution context 
        [parameter(Mandatory=$true, 
               HelpMessage="Specify the context database name",Position=1)] 
        [String] 
        [ValidateNotNullOrEmpty()] 
        $dbname = $(throw "dbname parameter is required."),
        
        #Location of example csv file to be uploaded to SQL table nyctaxi_joined_1_percent 
        [parameter(Mandatory=$true, 
               HelpMessage="Specify the path to the example csv file to be uploaded to SQL table nyctaxi_joined_1_percent",Position=1)] 
        [String] 
        [ValidateNotNullOrEmpty()] 
        $csvfilepath = $(throw "path to the example csv file is required."), 
 
        #The GO switch. Must be specified if T-SQL code is contain the GO instructions 
        [parameter(Mandatory=$false,Position=3)] 
        [Switch] 
        [AllowEmptyString()] 
        $go, 
 
        #MS SQL Server user name 
        [parameter(Mandatory=$false,Position=4)] 
        [String] 
        [AllowEmptyString()] 
        $u, 
 
        #MS SQL Server password name 
        [parameter(Mandatory=$false,Position=5)] 
        [String] 
        [AllowEmptyString()] 
        $p 
    ) 
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
#The GO switch is specified - parsing T-SQL code with GO
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

Write-Host "Start creating database and table on your SQL Server, and uploading data to the table. It may take a while..."
$start_time = Get-Date
ExecuteSQLFile $PWD"\create-db-tb-upload-data.sql" 1
$end_time = Get-Date
$time_span = $end_time - $start_time
$total_seconds = [math]::Round($time_span.TotalSeconds,2)
Write-Host "This step (creating database, tables and uploading data to table) takes $total_seconds seconds."
Write-Host "Start running the .sql files to register all functions and stored procedures used in this walkthrough..."
$start_time = Get-Date
ExecuteSQLFile $PWD"\fnCalculateDistance.sql" 1
ExecuteSQLFile $PWD"\fnEngineerFeatures.sql" 1
ExecuteSQLFile $PWD"\TrainTipPredictionModel.sql" 1
ExecuteSQLFile $PWD"\PlotHistogram.sql" 1
ExecuteSQLFile $PWD"\PlotInOutputFiles.sql" 1
ExecuteSQLFile $PWD"\PredictTip.sql" 1
ExecuteSQLFile $PWD"\PredictTipWithPassedInValues.sql" 1
Write-Host "Completed registering all functions and stored procedures used in this walkthrough."
$end_time = Get-Date
$time_span = $end_time - $start_time
$total_seconds = [math]::Round($time_span.TotalSeconds,2)
Write-Host "This step (registering all functions and stored procedures) takes $total_seconds seconds."
$SQLConnection.Close()
