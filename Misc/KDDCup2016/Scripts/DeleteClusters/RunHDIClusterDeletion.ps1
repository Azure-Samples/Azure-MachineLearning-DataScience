#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
Login-AzureRmAccount

#######################################################################
# SET WORKING FOLDER PATH
#######################################################################
Set-Location -Path C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts
$basepath = Get-Location
$currentPath = [string]$basepath + "\Configuration"
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
# INDICATE START AND END INDEXES OF CLUSTERS
#######################################################################
for($i=$clusterstartindex; $i -le $clusterendindex; $i++){
    $clustername = $clusterPrefix+$i;
	Start-Job -ScriptBlock {C:\Users\deguhath\Desktop\CDSP\Spark\KDDBlog\ProvisionScripts\ClusterDeletion\SubmitHDIClusterDeletion.ps1 $args[0] $args[1] $args[2]} -ArgumentList @($clustername, $resourcegroup, $profilepath)
}
