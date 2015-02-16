# Set database name, input data directory, and output log directory
# The example assumes the partitioned data files are named as <table_name>_<partition_number>.csv
# Assumes the input data files include a header line. Loading starts at line number 2.
$dbname = "TaxiNYC"
$indir  = "F:\Data\TaxiNYC\unzipped"
$logdir = "F:\Data\TaxiNYC\log"

# Select authentication mode - 0 = Windows, 1 = SQL
$sqlauth = 0

# For SQL authentication, set the server and user credentials
$sqlusr = "<user@server>"
$server = "<tcp:serverdns>"
$pass   = "<password>"

# Set number of partitions per table - Should match the number of input data files per table
$numofparts = 12

# First table: Set table name to be loaded, basename of input data files, input format file
$tbname1 = "nyctaxi_trip"
$basename1 = "trip_data"
$fmtfile1 = "F:\Data\TaxiNYC\nyctaxi_trip.xml"

# Second table: Set table name to be loaded, basename of input data files, input format file
$tbname2 = "nyctaxi_fare"
$basename2 = "trip_fare"
$fmtfile2 = "F:\Data\TaxiNYC\nyctaxi_fare.xml"

# Create log directory if it does not exist
New-Item -ErrorAction Ignore -ItemType directory -Path $logdir
  
# BCP example using Windows authentication
$ScriptBlock1 = {
   param($dbname, $tbname, $basename, $fmtfile, $indir, $logdir, $num)
   bcp ($dbname + ".." + $tbname) in ($indir + "\" + $basename + "_" + $num + ".csv") -o ($logdir + "\" + $tbname + "_" + $num + ".txt") -h "TABLOCK" -F 2 -C "RAW" -f ($fmtfile) -T -b 2500 -t "," -r \n
}

# BCP example using SQL authentication
$ScriptBlock2 = {
   param($dbname, $tbname, $basename, $fmtfile, $indir, $logdir, $num, $sqlusr, $server, $pass)
   bcp ($dbname + ".." + $tbname) in ($indir + "\" + $basename + "_" + $num + ".csv") -o ($logdir + "\" + $tbname + "_" + $num + ".txt") -h "TABLOCK" -F 2 -C "RAW" -f ($fmtfile) -U $sqlusr -S $server -P $pass -b 2500 -t "," -r \n
}

# Background processing of all partitions
for ($i=1; $i -le $numofparts; $i++)
{
   Write-Output "Submit loading trip and fare partitions # $i"
   if ($sqlauth -eq 0)
   {
      # Use Windows authentication
      Start-Job -ScriptBlock $ScriptBlock1 -Arg ($dbname, $tbname1, $basename1, $fmtfile1, $indir, $logdir, $i)
      Start-Job -ScriptBlock $ScriptBlock1 -Arg ($dbname, $tbname2, $basename2, $fmtfile2, $indir, $logdir, $i)
   } 
   else
   {
      # Use SQL authentication
      Start-Job -ScriptBlock $ScriptBlock2 -Arg ($dbname, $tbname1, $basename1, $fmtfile1, $indir, $logdir, $i, $sqlusr, $server, $pass)
      Start-Job -ScriptBlock $ScriptBlock2 -Arg ($dbname, $tbname2, $basename2, $fmtfile2, $indir, $logdir, $i, $sqlusr, $server, $pass)
   }
}

Get-Job

# Optional - Wait till all jobs complete and report date and time
date
While (Get-Job -State "Running") { Start-Sleep 10 }
date
