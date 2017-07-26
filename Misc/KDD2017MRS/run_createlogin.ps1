$server = 'localhost'
$serverName = Read-Host -Prompt 'Input the name of the SQL Server machine'
$numAccounts = Read-Host -Prompt 'Input the number of SQL accounts to create'
$accountFile = Read-Host -Prompt 'Input the path and file name that is going to store the account information'
$sqlFile = Read-Host -Prompt 'Input the path and name of the sql file'

#Connect to MS SQL Server 

try 

{ 

    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection 
    
    $SQLConnection.ConnectionString = "Server=" + $server + ";Database=master;Integrated Security=True" 

    $SQLConnection.Open() 

} 

#Error of connection 

catch 

{ 

    Write-Host $Error[0] -ForegroundColor Red 

    exit 1 

} 

#The GO switch is specified - parsing T-SQL code with GO

function ExecuteSQLFile($sqlfile, $login, $pass)

{ 

    
    #Reading the T-SQL file as a whole packet 

    $SQLCommandText = @(Get-Content -Path $sqlfile) 
    $SQLCommandText = $SQLCommandText -replace "<sqllogin>", $login
    $SQLCommandText = $SQLCommandText -replace "<password>", $pass
    $SQLCommandText | Out-File "tmp.sql"

    #Execution of SQL packet 

    foreach($SQLString in  $SQLCommandText) 

    { 

        if($SQLString -ne "go") 

        {

            $SQLPacket += $SQLString + "`n"

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
    

    Write-Host "-----------------------------------------" 

    Write-Host $sqlfile "execution done"

}



Write-Host "Start creating logins for your database. It may take a while..."
echo "server_name, login_name, password" >> $accountFile
$start_time = Get-Date
for ($i=0; $i -lt $numAccounts; $i++) {
    $pwd_rn = Get-Random -Maximum 99999 -Minimum 10000
    $login_rn = Get-Random -Maximum 99999 -Minimum 10000
    $login_name = "sqluser" + $login_rn
    $pass = "Kdd17@Halifax_" + $pwd_rn
    
    ExecuteSQLFile $sqlFile $login_name $pass
    echo $serverName","$login_name","$pass >> $accountFile
}

$end_time = Get-Date

$time_span = $end_time - $start_time

$total_seconds = [math]::Round($time_span.TotalSeconds,2)

Write-Host "This step (creating logins) takes $total_seconds seconds."