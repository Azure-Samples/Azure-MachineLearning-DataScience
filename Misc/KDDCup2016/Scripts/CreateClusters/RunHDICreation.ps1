#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
Login-AzureRmAccount

#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
Set-Location -Path C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts
$currentPathTmp = Get-Location
$currentPath = [string]$currentPathTmp
#######################################################################
# READ IN PARAMETERS
#######################################################################
#READ IN PARAMETER CSV FILE
$paramFile = Import-Csv ClusterParameters.csv

#GET ALL THE PARAMETERS FROM THE PARAMETER FILE
$scriptpathnametmp = $paramFile | Where-Object {$_.Parameter -eq "ScriptPath"} | % {$_.Value}
$scriptpathname = [string]$scriptpathnametmp
$subscriptionname = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionName"} | % {$_.Value}
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $paramFile | Where-Object {$_.Parameter -eq "TenantID"} | % {$_.Value}
$resourcegroup = $paramFile | Where-Object {$_.Parameter -eq "ResourceGroup"} | % {$_.Value}
$location = $paramFile | Where-Object {$_.Parameter -eq "Location"} | % {$_.Value}
$sourcestoragename = $paramFile | Where-Object {$_.Parameter -eq "TenantID"} | % {$_.Value}
$profilepathtmp = $paramFile | Where-Object {$_.Parameter -eq "Profilepath"} | % {$_.Value}
$profilepath = $currentPath + "\" + [string]$profilePathTmp
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterStartIndex"} | % {$_.Value}; $clusterstartindex = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterEndIndex"} | % {$_.Value}; $clusterendindex = [int]$tmp;
$clusterprefix = $paramFile | Where-Object {$_.Parameter -eq "ClusterPrefix"} | % {$_.Value}
$sourcedataresourcegroup = $paramFile | Where-Object {$_.Parameter -eq "SourceDataResourceGroup"} | % {$_.Value};
$sourcedatastoragename = $paramFile | Where-Object {$_.Parameter -eq "SourceDataStorageName"} | % {$_.Value};
$sourcedatacontainername = $paramFile | Where-Object {$_.Parameter -eq "SourceDataContainerName"} | % {$_.Value}
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterInfoOutputFileName"} | % {$_.Value}; $clusterinfooutputfilename = $currentPath + "\" + [string]$tmp 
$tmp = $paramFile | Where-Object {$_.Parameter -eq "SubmitClusterCreationFileName"} | % {$_.Value}; $submitclustercreationfilename = $currentPath + "\" + [string]$tmp 

#######################################################################
# SET AZURE SUBSCRIPTIONS & SAVE PROFILE INFORMATION IN A FILE
#######################################################################
Set-AzureRmContext -SubscriptionID $subscriptionid -TenantID $tenantid
Save-AzureRmProfile -Path $profilepath

#######################################################################
# SUBMIT CLUSTER JOBS TO BE RUN IN PARALLEL
# NOTE: YOU NEED TO SPECIFY THE LOCATION OF FUNCTION FILE, C:\Users\deguhath\Source\Repos\KDD2016 Spark\Scripts\SubmitHDICreation.ps1 
#######################################################################
for($i=$clusterstartindex; $i -le $clusterendindex; $i++) {
	$clustername = $clusterprefix+$i;
	$randnum = Get-Random -minimum 1 -maximum 100001
	$clusterpasswd = $clustername.substring(0,1).toupper() + $clustername.substring(1).tolower() + "_" + $randnum
	Set-Location -Path $currentPath
	$clustername,$clusterpasswd -join ',' | out-file -filepath $clusterinfooutputfilename -append -Width 200;
	
	## SPECIFY ABSOLUTE PATH TO THE SCRIPT THAT YOU WANT TO SUBMIT AND RUN IN PARALLEL 
	Start-Job -ScriptBlock {C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts\SubmitHDICreation.ps1 $args[0] $args[1] $args[2] $args[3]} -ArgumentList @($clustername, $resourcegroup, $profilepath, $clusterpasswd)
}
#######################################################################
# END
#######################################################################
