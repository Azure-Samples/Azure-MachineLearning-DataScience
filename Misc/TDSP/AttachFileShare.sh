#!/bin/bash

#install jq to process json file
sudo yum install jq

function mountfileservices {
  echo -n " Start getting the list of subscriptions under your Azure account..."
  azure config mode arm
  loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`

  if [ "$loginstat" = "False" ]
	   then
	   # Login to your Azure account
	   echo "Follow directions on screen to login to your Azure account"
	   azure login
  fi
  
  azure account list --json > acctlist.json
  num_sub=$(jq '.| length' acctlist.json)
  sublist=$(cat acctlist.json | jq '.[] .name' --raw-output| cat -n)  
  echo " Here are the subscription names under your account :"
  echo
  echo "$sublist"
  echo
  echo -n "Do you have a file with the information of the file share you want to mount? Y/N "
  read inputfileyesorno
  if [ "${inputfileyesorno,,}" != 'n' ]
	   then
	   inputfileyesorno='y'
  fi

  sub='NA'
  sa='NA'
  sharename='NA'

  if [ -z "$inputfileyesorno" ] || [ "${inputfileyesorno,,}" = 'y' ]
	   then
	   inputfilequit=false
	   inputfileright=false
	   while [ $inputfilequit = false ] && [  $inputfileright = false ]
	   do
			echo -n "Please provide the name of the file with the information of the file share you want to mount: "
			read filename
			if [ -z "$filename" ]
				 then 
				 echo -n "File name cannnot be empty. R-retry/S-skip: "
				 read retryinput
				 if [ "${retryinput,,}" = 's' ]
					  then
					  inputfilequit=true
				 fi
			else
				 if [ ! -f "$filename" ]
					  then
					  echo -n "File does not exist. R-retry/S-skip: " 
					  read retryinput
					  if [ "${retryinput,,}" = 's' ]
						   then 
						   inputfilequit=true
					  fi
				 else
					  inputfileright=true
				 fi
			fi
	   done
	   if [ $inputfileright = true ]
			then
			#cd
			sub=$(cat $filename | cut -d':' -f2  | head -2 | tail -1)
			#echo "from the file sub is $sub"
			sa=$(cat $filename | cut -d':' -f2  | head -3 | tail -1)
			#echo "from the file sa is $sa"
			sharename=$(cat $filename | cut -d':' -f2  | head -4 | tail -1)
			#echo "from the file sharename is $sharename"
			if [ "$sub" = 'NA' ] || [ "$sa" = 'NA' ] || [ "$sharename" = 'NA' ]
				 then
				 echo -n "Information about the file share to be mounted is incomplete. You have to manually input information later. "
				 sub='NA'
				 sa='NA'
				 sharename='NA'
			fi
		fi
  fi

 subnameright=false
 quitornot=false
 while [  $subnameright = false ] && [ $quitornot = false ]
 do
   if [ "$sub" = 'NA' ]
		then
		echo -n "Enter the subscription name where the Azure file share service has been created: "
		read sub
   fi
   azure account list --json > acctlist.json
   sublist=$(cat acctlist.json | jq '.[] .name' --raw-output)
   if [[ $sublist=~$sub ]]
		then
		#echo "$sub is in $sublist"
		subnameright=true
   else
		echo -n "The subscription name you input does not exist. [R]-retry/Q-quit: "
		read quitornotask
		sub='NA'
		sa='NA'
		sharename='NA'
		if [ "${quitornotask,,}" = 'q' ]
		 then
			 echo "Mounting Azure file share quit. "
			 quitornot=true
		fi
   fi
 done

 if [ $subnameright = true ]
  then
  retrycount=0
  getstoragesucceed=false
  azure account list --json >acctlist.json
  num_sub=$(jq '.| length' acctlist.json)
  azure account set "$sub"
  echo -n "Start getting the list of storage accounts under your subscription $sub "
  while [ $getstoragesucceed = false ] && [ $retrycount -eq 0 ]
  do
	   azure storage account list --json > storlist.json
	   num_stor=$(jq '.| length' storlist.json)
	   if [ "$num_stor" -gt 0 ]
			then
			getstoragesucceed=true
	   fi
	   if [ $getstoragesucceed = false ]
			then
			let retrycount=retrycount+1
			echo -n "Trial $retrycount failed to get storage account list from your subscription $sub. Wait for 1 second to try again. "
			sleep 1
	   fi
  done
  
  if [  $getstoragesucceed = false ] && [ "$retrycount" -eq 10 ]
	   then 
	   echo -n "It has failed 10 times getting the storage account. Retry sometime later. "
  else
   azure storage account list --json > storlist.json
   num_stor=$(jq '.| length' storlist.json)
   storageaccountnames=$(cat storlist.json | jq '.[] .name' --raw-output | cat -n)
   resourcegroupnames=$(cat storlist.json | jq '.[] .resourceGroup' --raw-output | cat -n)
   echo -n "Here are the storage account names under subscription $sub "
   echo
   echo -n "$storageaccountnames"
   echo
   goodsaname=false
   quitornot=false
   while [  $goodsaname = false ] && [  $quitornot = false ]
   do
		if [ "$sa" = 'NA' ]
			 then
			 echo -n "Enter the index of the storage account name where your Azure file share you want to mount is created: "
			 read saindex
			 if [ "$saindex" -gt 0 ] && [ "$saindex" -le $num_stor ]
				  then
				  let saindex2=saindex-1
				  sa=$(cat storlist.json | jq  '.['$saindex2'] .name' --raw-output)
				  rg=$(cat storlist.json | jq  '.['$saindex2'] .resourceGroup' --raw-output) 
				  goodsaname=true
			 else
				  echo -n "Index out of bounds (1 - $num_stor ) [R]-retry/Q-quit "
				  read quitsa
				  if [ "${quitsa,,}" = 'q' ]
				   then
				   quitornot=true
				  fi
			 fi
		else
			 storageaccountnames2=$(cat storlist.json | jq '.[] .name' --raw-output)
			 if [[ ! $storageaccountnames2=~$sa ]]
				  then
				  echo -n " Storage account name $sa from the file does not exist. Please manually input it next. "
				  sa='NA'
				  sharename='NA'
			 else
				  rg=$(cat storlist.json | jq '.[] | select (.name == "'$sa'" )' | jq ' .resourceGroup' --raw-output)
				  goodsaname=true 
			 fi
		fi
   done
   
   if [ $goodsaname = true ]
    then
    sharenameexist=false
    quitnewsharename=false
    #storkey 
    sharenameright=false
    quitornot=false
    while [ $sharenameexist = false ] && [  $quitnewsharename = false ]
    do
     while [ $sharenameright = false ] && [  $quitornot = false ]
     do
		  if [ "$sharename" = 'NA' ]
			   then
			   echo -n "Enter the name for the file share to mount (lower case only): "
			   read sharename
		  elif [ -z "${sharename,,}" ]
			   then 
			   echo -n "File share name cannot be empty. [R]-retry/Q-quit. "
			   read quitornotanswer
			   if [ "${quitornotanswer,,}" = 'q' ]
					then
					quitornot=true
			   fi
		  else
			   sharenameright=true
		  fi
     done
     
     if [ $sharenameright = true ]
      then
      drivenameright=false
      existingdisks=$(df -h)
      existingdisknames=$(df -h | cut -d" " -f1 | tail -n+2)  
      echo -n "Existing disk names are: "
      echo
      echo -n "$existingdisks" 
      echo
      quitdrivename=false
      while [ $drivenameright = false ] && [  $quitdrivename = false ]
      do
		   echo -n "Enter the name of the drive to be added to your virtual machine. This name should be diferent from the disk names your virtual machine has: "
		   read drivename
		   drivelist=$(df -h | rev | cut -d" " -f1 | rev)
		   if [[ $drivelist=~$drivename ]]
		   #if echo "$sublist" | grep -q "$sub" ; then echo "matched" ;else echo "not matched"; fi;
				then
				echo -n "The disk drive $drivename you want to mount the file sahre already exists. [R]-retry/Q-quit"
				read inputnewdrive
				if [ "${inputnewdrive,,}" = 'q' ]
					 then
					 quitdrivename=true
				fi
		   else
				drivenameright=true
		   fi
      done
      
      if [ $drivenameright = true ]
       then
		   echo -n "File share $sharename will be mounted to your virtual machine as drive $drivename "
		   echo 
		   k=`azure storage account keys list  $sa -g $rg --json |  python -c 'import json,sys;obj=json.load(sys.stdin)[0]["value"];print(obj)'`
		   sudo mkdir -p /$drivename
		   sudo mount -t cifs //$sa.file.core.windows.net/$sharename /$drivename -o vers=3.0,username=$sa,password=$k,dir_mode=0777,file_mode=0777
		   sharenameexist=true
      fi
     fi
    done
   fi 
  fi
 fi
}


#Mount share files to Linux DSVM


 echo -n "Do you want to mount an Azure File share service to your Azure Virtual Machine? [Y]-yes/N -no to quit: "
 read mountornot
 if [ -z "${mountornot,,}" ] || [ "${mountornot,,}" = 'y' ]
  then
  mountfileservices
  others=1
  while [ $others -eq 1 ]
  do
   echo -n "Do you want to mount other Azure File share services? [Y]-yes/N -no to quit: "
   read mountornot
   if [ -z "${mountornot,,}" ] || [ "${mountornot,,}" = 'y' ]
    then
    mountfileservices
   else
    others=0
   fi
  done
 fi

rm -rf acctlist.json storlist.json grplist.json
