$TARGETDIR="C:\temp"
if(!(Test-Path -Path $TARGETDIR )){
    New-Item -ItemType directory -Path $TARGETDIR
}

$clnt = new-object System.Net.WebClient
    	
$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_create_db_and_tables.hql"
    	
$file = "c:\temp\sample_hive_create_db_and_tables.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_load_data_by_partitions.hql"
    	
$file = "c:\temp\sample_hive_load_data_by_partitions.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_trip_count_by_medallion.hql"
    	
$file = "c:\temp\sample_hive_trip_count_by_medallion.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_trip_count_by_medallion_license.hql"
    	
$file = "c:\temp\sample_hive_trip_count_by_medallion_license.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_quality_assessment.hql"
    	
$file = "c:\temp\sample_hive_quality_assessment.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_tipped_frequencies.hql"
    	
$file = "c:\temp\sample_hive_tipped_frequencies.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_tip_range_frequencies.hql"
    	
$file = "c:\temp\sample_hive_tip_range_frequencies.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_trip_direct_distance.hql"
    	
$file = "c:\temp\sample_hive_trip_direct_distance.hql"
    
$clnt.DownloadFile($url,$file)

$url = "https://raw.githubusercontent.com/Azure/Azure-MachineLearning-DataScience/master/Misc/DataScienceProcess/DataScienceScripts/sample_hive_prepare_for_aml.hql"
    	
$file = "c:\temp\sample_hive_prepare_for_aml.hql"
    
$clnt.DownloadFile($url,$file)