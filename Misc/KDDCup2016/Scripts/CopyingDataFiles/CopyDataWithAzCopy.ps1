#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
Login-AzureRmAccount

#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
Set-Location -Path C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts

$basepath= Get-Location
$currentPath = [string]$basepath + "\Configuration"
#######################################################################
# READ IN PARAMETERS
#######################################################################
#READ IN PARAMETER CSV FILE
$paramFile = Import-Csv ClusterParameters.csv

#GET ALL THE PARAMETERS FROM THE PARAMETER FILE
$subscriptionname = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionName"} | % {$_.Value}
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $paramFile | Where-Object {$_.Parameter -eq "TenantID"} | % {$_.Value}
$resourcegroup = $paramFile | Where-Object {$_.Parameter -eq "ResourceGroup"} | % {$_.Value}
$location = $paramFile | Where-Object {$_.Parameter -eq "Location"} | % {$_.Value}
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterStartIndex"} | % {$_.Value}; $clusterstartindex = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterEndIndex"} | % {$_.Value}; $clusterendindex = [int]$tmp;
$clusterprefix = $paramFile | Where-Object {$_.Parameter -eq "ClusterPrefix"} | % {$_.Value}
$sourcedatastoragename = $paramFile | Where-Object {$_.Parameter -eq "SourceDataStorageName"} | % {$_.Value};
$sourcedatacontainername = $paramFile | Where-Object {$_.Parameter -eq "SourceDataContainerName"} | % {$_.Value}

#######################################################################
# Set AzureRm contex and destination key for destination storage account
#######################################################################
# Set Azure context
Set-AzureRmContext -SubscriptionID $subscriptionid -TenantID $tenantid

#######################################################################
# Copy files using AzCopy
#######################################################################
for ($i=$clusterstartIndex; $i -le $clusterendIndex; $i++){
    $destinationStorageName = $clusterPrefix+$i+'storage';
 	$destinationContainerName = $clusterPrefix+$i;
	
    # Get destination storage account key
    $destKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroup -Name $destinationStorageName).Value[0]
    	
	# Copy airline data, csv data in parts
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/FlightDelay"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/Airline"
	&'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /sourceType:blob /destType:blob /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey  /S /V /Y

    # Copy NYC taxi original csv data for month 12
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/NYCTaxi/Csv"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/NYCTaxi/KDD2016"
    &'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /S /V /Y /Pattern:"trip_data_12.csv"
    &'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /S /V /Y /Pattern:"trip_fare_12.csv"

    # Copy sampled NYC taxi joined data (small file in parquet format)
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/NYCTaxi/JoinedParquetSampledFile"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/NYCTaxi/KDD2016/JoinedParquetSampledFile"
    &'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey  /Pattern:"part-r" /S /V /Y
}
