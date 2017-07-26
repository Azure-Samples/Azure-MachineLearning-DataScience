#######################################################################
# FIRST LOGIN AND SAVE PROFILE IN A FILE WHICH WILL BE USED FOR SUBMITTING JOBS IN PARALLEL
#######################################################################
Login-AzureRmAccount

$SubscriptionName = "Azure Internal - KDD 2016"
$SubscriptionID = "3a6c6f94-9a97-4b16-85ba-53a9da62f597"
$TenantID = "72f988bf-86f1-41af-91ab-2d7cd011db47"
$resourcegroup = "StrataDevDSVM";
$location = "West US"
Set-AzureRmContext -SubscriptionID $SubscriptionID -TenantID $TenantID
$profilepath = "C:\Users\deguhath\Desktop\CDSP\Spark\StrataSanJose\ProvisionScripts\rprofile"
Save-AzureRmProfile -Path $profilepath

#######################################################################
# SPECIFY CLUSTER PREFIX + OUTPUT FILE WHERE CLUSTER PWDS WILL BE SAVED
#######################################################################
$dsvmPrefix = "stratasjr";

#######################################################################
# INDICATE START AND END INDEXES OF CLUSTERS
#######################################################################
$dsvmstartIndex = 1;
$dsvmendIndex = 30;

#######################################################################
# SUBMIT CLUSTER JOBS TO BE RUN IN PARALLEL
# NOTE: YOU NEED TO SPECIFY THE LOCATION OF FUNCTION FILE, C:\Users\deguhath\Source\Repos\KDD2016 Spark\Scripts\SubmitHDICreation.ps1 
#######################################################################
for($i=$dsvmstartIndex; $i -le $dsvmendIndex; $i++){
	$vmname = $dsvmPrefix+$i;
	Start-Job -ScriptBlock {C:\Users\deguhath\Desktop\CDSP\Spark\StrataSanJose\ProvisionScripts\SubmitDSVMDeletion.ps1 $args[0] $args[1] $args[2]} -ArgumentList @($vmname, $resourcegroup, $profilepath)
}
#######################################################################
# END
#######################################################################