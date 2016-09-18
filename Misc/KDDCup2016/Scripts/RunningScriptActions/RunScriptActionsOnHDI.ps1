#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
Login-AzureRmAccount
#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
Set-Location -Path C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts
#######################################################################
# READ IN CLUSTER CONFIGURATION PARAMETERS
#######################################################################
#READ IN PARAMETER CSV CONFIGURATION FILE
$basepath = Get-Location
$currentPath = [string]$basepath + "\Configuration"
Set-Location -Path $currentPath
$paramFile = Import-Csv ClusterParameters.csv

#GET ALL THE PARAMETERS FROM THE PARAMETER FILE
$scriptpathnametmp = $paramFile | Where-Object {$_.Parameter -eq "ScriptPath"} | % {$_.Value}
$scriptpathname = [string]$scriptpathnametmp
$subscriptionname = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionName"} | % {$_.Value}
$subscriptionid = $paramFile | Where-Object {$_.Parameter -eq "SubscriptionID"} | % {$_.Value}
$tenantid = $paramFile | Where-Object {$_.Parameter -eq "TenantID"} | % {$_.Value}
$resourcegroup = $paramFile | Where-Object {$_.Parameter -eq "ResourceGroup"} | % {$_.Value}
$location = $paramFile | Where-Object {$_.Parameter -eq "Location"} | % {$_.Value}

$profilepathtmp = $paramFile | Where-Object {$_.Parameter -eq "Profilepath"} | % {$_.Value}; $profilepath = $currentPath + "\" + [string]$profilePathTmp
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterStartIndex"} | % {$_.Value}; $clusterstartindex = [int]$tmp;
$tmp = $paramFile | Where-Object {$_.Parameter -eq "ClusterEndIndex"} | % {$_.Value}; $clusterendindex = [int]$tmp;
$clusterprefix = $paramFile | Where-Object {$_.Parameter -eq "ClusterPrefix"} | % {$_.Value}
#######################################################################
# SET AZURE SUBSCRIPTIONS & SAVE PROFILE INFORMATION IN A FILE
#######################################################################
Set-AzureRmContext -SubscriptionID $subscriptionid -TenantID $tenantid
Save-AzureRmProfile -Path $profilepath
#######################################################################
# SUBMIT CLUSTER JOBS TO BE RUN IN PARALLEL
# NOTE: YOU NEED TO SPECIFY THE LOCATION OF FUNCTION FILE, C:\Users\deguhath\Desktop\CDSP\Spark\KDD\ProvisionScripts\SubmitScriptActionsOnHDI.ps1
#######################################################################
for($i=$clusterstartIndex; $i -le $clusterendIndex; $i++){
	$clustername = $clusterPrefix+$i;
	Start-Job -ScriptBlock {C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts\ScriptActions\SubmitScriptActionsOnHDI.ps1 $args[0] $args[1]} -ArgumentList @($clustername, $profilepath)
}
#######################################################################
# END
#######################################################################
