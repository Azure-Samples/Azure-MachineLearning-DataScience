#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
Login-AzureRmAccount

$SubscriptionName = "Microsoft Azure Internal - Vanja"
$SubscriptionID = "<subscription id>"
$TenantID = "<tenant id>"
$resourcegroup = "KDDHalifax2017";
$location = "West US"
#$sourceStorageName = "scaler";
Set-AzureRmContext -SubscriptionID $SubscriptionID -TenantID $TenantID
#Get-AzureSubscription -Current
#$sourceKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourcegroup -Name $sourceStorageName).Value[0]
$profilepath = "C:\Users\vapaunic\repos\KDD2017R\Scripts\rprofile2"
Save-AzureRmContext -Path $profilepath

#######################################################################
# SPECIFY CLUSTER PREFIX + OUTPUT FILE WHERE CLUSTER PWDS WILL BE SAVED
#######################################################################
$dsvmPrefix = "kddr";
$outFile = "C:\Users\vapaunic\repos\KDD2017R\Scripts\dsvmOutFileIS.csv"

#######################################################################
# INDICATE START AND END INDEXES OF CLUSTERS
#######################################################################
$dsvmstartIndex = 1;
$dsvmendIndex = 5;

#######################################################################
# SUBMIT CLUSTER JOBS TO BE RUN IN PARALLEL
# NOTE: YOU NEED TO SPECIFY THE LOCATION OF FUNCTION FILE, C:\Users\vapaunic\repos\KDD2017R\Scripts\SubmitDSVMCreation.ps1 
#######################################################################
for($i=$dsvmstartIndex; $i -le $dsvmendIndex; $i++){
	$vmname = $dsvmPrefix+$i;
	$randnum = Get-Random -minimum 1 -maximum 100001
	$adminPassword = $vmname + "_" + $randnum
	$vmname,$adminPassword -join ',' | out-file -filepath $outFile -append -Width 200;

	Start-Job -ScriptBlock {C:\Users\vapaunic\repos\KDD2017R\Scripts\SubmitDSVMCreation.ps1 $args[0] $args[1] $args[2] $args[3]} -ArgumentList @($vmname, $resourcegroup, $profilepath, $adminPassword)
}
#######################################################################
# END
#######################################################################