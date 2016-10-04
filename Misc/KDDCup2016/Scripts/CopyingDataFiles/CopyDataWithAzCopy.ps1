################################################################################
#    Copyright (c) Microsoft. All rights reserved.
#    
#    Apache 2.0 License
#    
#    You may obtain a copy of the License at
#    http://www.apache.org/licenses/LICENSE-2.0
#    
#    Unless required by applicable law or agreed to in writing, software 
#    distributed under the License is distributed on an "AS IS" BASIS, 
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or 
#    implied. See the License for the specific language governing 
#    permissions and limitations under the License.
#
################################################################################


#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
$AzProfile = Login-AzureRmAccount

#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
$basepath = "C:\RSpark\RSpark_KDD2016"

#######################################################################
# READ IN CLUSTER CONFIGURATION PARAMETERS
#######################################################################
#READ IN PARAMETER CSV CONFIGURATION FILE
$paramFile = Import-Csv $basepath\Configuration\ClusterParameters.csv

#GET ALL THE PARAMETERS FROM THE PARAMETER FILE
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $AzProfile.Context.Tenant.TenantId;
$resourcegroup = $paramFile | Where-Object {$_.Parameter -eq "ResourceGroup"} | % {$_.Value}
$profilepathtmp = $paramFile | Where-Object {$_.Parameter -eq "Profilepath"} | % {$_.Value}; $profilepath = $currentPath + "\Configuration\" + [string]$tmp
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

    ## DATASETS FOR FLIGHT DELAY 
	# Copy airline data, csv data in parts
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/FlightDelay/AirlineSubsetCsv"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/Airline/AirlineSubsetCsv"
	&'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /sourceType:blob /destType:blob /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /Pattern:"part-0" /S /V /Y

	# Copy weather data, csv data in parts
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/FlightDelay/WeatherSubsetCsv"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/Airline/WeatherSubsetCsv"
	&'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /sourceType:blob /destType:blob /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /Pattern:"part-0" /S /V /Y

    ## DATASETS FOR NYC TAXI TRIP / FARE
    # Copy NYC taxi original csv data for month 12
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/NYCTaxi/Csv"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/NYCTaxi/KDD2016"
    &'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /S /V /Y /Pattern:"trip_data_12.csv"
    &'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /S /V /Y /Pattern:"trip_fare_12.csv"

    # Copy sampled NYC taxi joined data (small file in parquet format)
    $destStorage = "https://$destinationStorageName.blob.core.windows.net/$destinationContainerName/HdiSamples/HdiSamples/NYCTaxi/JoinedParquetSampledFile"
    $sourceStorage = "https://$sourcedatastoragename.blob.core.windows.net/$sourcedatacontainername/NYCTaxi/KDD2016/JoinedParquetSampledFile"
    &'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$sourceStorage /Dest:$destStorage /DestKey:$destKey /Pattern:"part-r" /S /V /Y
}
#######################################################################
# END
#######################################################################