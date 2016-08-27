#!/bin/bash

#Install jq to process json format subscription data
sudo yum install jq

echo -n "Do you want to create an Azure file share service for your team? [Y]/N "
read createornot

if [ -z "${createornot,,}" ] || [ "${createornot,,}" = 'y' ]
then 
	  azure config mode arm
	  loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
	 
	  if [ "$loginstat" = "False" ]
		   then
		   # Login to your Azure account
		   echo "Follow directions on screen to login to your Azure account"
		   azure login
	  fi
	  
	  subnameright=false
	  quitornot=false
		
	  azure account list --json > acctlist.json
	  num_sub=$(jq '.| length' acctlist.json)
	  sublist=$(cat acctlist.json | jq '.[] .name' --raw-output| cat -n) 
	  echo -n "Here are your subscriptions:"
	  echo
	  echo "$sublist"
	  echo

	  while [ $subnameright = false ] && [ $quitornot = false ]
	  do
		   echo -n "Enter the index of the subscription name where resources will be created (1-$num_sub): "
		    
		   read subnbr
		  
		   if [ $subnbr -gt 0 ] && [ $subnbr -le $num_sub ]
				then
				let subnbr2=subnbr-1
				sub=$(cat acctlist.json | jq  '.['$subnbr2'] .name' --raw-output)
				echo -n "You selected $subnbr: $sub. [Y]-yes to continue/N-no to reselect: "  
				read selectedright
				if [ -z "${selectedright,,}" ] || [ "${selectedright,,}" = 'y' ]
					 then
					 subnameright=true
				fi
		   fi

		   if [  $subnameright = false ]
				then
				echo -n "The number you entered is out of bound. [R] -retry/Q -quit"
				read quitornotask
				if [ -z "${quitornotask,,}" ] || [ "${quitornotask,,}" = 'q' ]
					 then 
					 echo -n "Creating Azure file share service quit."
					 quitornot=true
				fi
		   fi
	  done

		if [ $subnameright = true ]
		 then
			   # Set the default subscription where we will create the share
			   azure account set "$sub"
			   
			   echo "Getting the list of storage accounts under subscription $sub: "
			   echo
			   # Choose from existing storage account
			   azure storage account list --json > storlist.json
			   storlist=$(cat storlist.json | jq '.[] .name' --raw-output | cat -n)
			   echo "Here are the storage account names under your subscription $sub: "
			   echo
			   echo "$storlist"
			   echo
			  
			   azure group list --json > grplist.json
			   grplist=$(cat grplist.json | jq '.[] .name' --raw-output | cat -n)
				  
			   echo -n "Do you want to create a new storage storage account for your Azure file share? [Y]/N: "
			   read createornotsa
			   #echo $createornotsa
			   saretryornot='r'
			   if [ -z "${createornotsa,,}" ] || [ "${createornotsa,,}" = 'y' ]
					then
					havegoodsaname=false
					saretry=true
					#loc='southcentralus'    
					while [  $havegoodsaname = false ] && [  $saretry = true ]
					do
						 echo -n "Enter the storage account name to create (only accept lower case letters and numbers): "
						 read sa
						 sa=${sa,,}
						 azure storage account list --json > storlist.json
						 rg=$(cat storlist.json | jq '.[] | select (.name == "'$sa'" )' | jq ' .resourceGroup' --raw-output)
						 storlist2=$(cat storlist.json | jq '.[] .name' --raw-output)
						 if [[ $storlist2 =~ $sa ]]
								  then
									  echo -n " Storage account already exists. [R]-retry/U-use/Q-quit" 
									  read saretryornot
									  
									  if [ "${saretryornot,,}" = 'q' ]
										   then 
										   saretry=false   
									  elif [ "${saretryornot,,}" = 'u' ]
										   then
										   echo -n "You choose to use an existing storage account $sa. Y-continue/R-retry"
										   read useexisting       
										   if [ -z "${useexisting,,}" ] || [ "${useexisting,,}" = 'y' ]
												then 
												havegoodsaname=true
												echo -n "Existing storage $sa will be used. Its resource group is $rg. "
												echo
										   fi
									  fi
						 else
							  echo -n "Storage account $sa will be created ..."
							  echo
							  echo -n "You need to select the resource group name under which the storage account will be created."
							  echo
							  rgvalid=false 
							  azure group list --json > grplist.json
							  grplist=$(cat grplist.json | jq '.[] .name' --raw-output | cat -n)
							  echo -n "Here is the list of existing resource group names: "
							  echo
							  echo "$grplist"
							  echo

							  while [ $rgvalid = false ]
							  do
								   num_rg=$(jq '.| length' grplist.json)
								   echo -n "Enter the index of resource group you want to use: 0-New/1-$num_rg -use existing ones " 
								   read grpnbr
								   if [ "$grpnbr" = 0 ]
										then
										echo -n "Please input the name of a new resource group to create (only allows lower cae letters, numbers,underline, and hyphen)： "
										read rg
										rg=${rg,,}
										grplist2=$(cat grplist.json | jq '.[] .name' --raw-output)
										if [[ $grplist2 =~ $rg ]] 
											 then 
											 echo -n "Resource group $rg exists. [U]-use/R-retry: "
											 read useexisting
											 if [ -z "${useexisting,,}" ] || [ "${useexisting,,}" = 'u' ]
												  then
												  rgvalid=true 
											 fi
										else
											 rgvalid=true
										fi
								   else
										if [ "$grpnbr" -gt 0 ] && [ "$grpnbr" -le $num_rg ]
											 then
											 let grpnbr2=grpnbr-1
											 grp=$(cat grplist.json | jq  '.['$grpnbr2'] .name' --raw-output)
											 echo -n "You selected $grp. [Y]-continue/R-retry"
											 read continue
											 if [ -z "${continue,,}" ] || [ "${continue,,}" = 'y' ]
											  then
											  rgvalid=true
											 fi
										else
											  echo -n "Selected index of existing resource group out of bounds. Retry..."
										fi
								   fi
							  done

							  havegoodsaname=true
							  grplist3=$(cat grplist.json | jq '.[] .name' --raw-output)
							  if [[ $grplist3 =~ $rg ]]
								   then
								   echo -n "Start creating storage account $sa under resource group $rg. "
							  else 
								   echo -n "Start creating resource group $rg. "
								   azure group create $rg southcentralus
								   echo -n "Start creating storage account $sa under resource group $rg. "
								   azure storage account create $sa -g $rg --sku-name 'LRS' -l southcentralus --kind Storage
							  fi
						 fi
					done
			   else
					validexistingsaname=false
					saretry=true
					azure storage account list --json > storlist.json
					num_stor=$(jq '.| length' storlist.json)
					while [ $validexistingsaname = false ] && [ $saretry = true ]
					do
						 echo -n "Enter the index of the storage account to use (1 - $num_stor ): "
						 read saindex
						 if [ "$saindex" -gt 0 ] && [ "$saindex" -le "$num_stor" ]
							  then
							  let saindex2=saindex-1
							  sa=$(cat storlist.json | jq  '.['$saindex2'] .name' --raw-output)
							  rg=$(cat storlist.json | jq  '.['$saindex2'] .resourceGroup' --raw-output)
							  echo -n "You selected storage account $sa. [Y]-continue/N-reselect: "
							  read saconfirm
							  if [ -z "${saconfirm,,}" ] || [ "${saconfirm,,}" = 'y' ]
								   then
								   echo -n "Stoage account $sa is selected. Its resource group is $rg. "
								   validexistingsaname=true
							  fi  
						 else
							  echo -n "Selected index of storage account out of bounds. [R]-retry/Q-quit: "
							  read saretryornot
							  if [ "${saretryornot,,}" = 'q' ]
								   then
								   saretry=false
								   echo -n "Quitting ..." 
							  fi
						 fi  
					done 
				fi
			  echo $rg
			  echo $sa

			  #azure storage account set -g $rg -s $sa

			  validsharename=false
			  quitcreateshare=false
			  while [ $validsharename = false ] && [  $quitcreateshare = false ]
			  do
				   echo -n "Enter the name of the file share service to create (lower case characters, numbers, and - are accepted): "
				   read sharename0

				   if [ -z "$sharename0" ]
						then
						echo -n "You entered an empty file share name. [R]-retry/Q-quit: "
						read retrysharename
						if [ "${retrysharename,,}" = 'q' ]
							 then 
							 quitcreateshare=true
						fi
				   else
						sharename=${sharename0,,}
						if [ "$sharename" != "$sharename0" ] 
							 then
							 echo "Invalid file share name '$sharename0' converted to '$sharename'"
							 validsharename=true
						else 
							validsharename=true
						fi
				   fi
			  done
			 

			   if [ $validsharename = true ]
					then
					x=`azure storage account connectionstring show $sa -g $rg --json`
					# Extract the storage connectionstring with the keys
					y=`echo $x | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["string"])'`
					export AZURE_STORAGE_CONNECTION_STRING="$y"
					azure storage share create $sharename
					#azure storage directory create $sharename 
					#azure storage directory create $sharename  -p 'data'
					echo -n "An Azure file share service created. It can be later mounted to the Azure virtual machine screated for your team projects. "
					echo
					echo -n "Please keep a note for the information of the Azure file share service. It will be needed in the future when mounting it to Azure virtual machines."
					echo
					echo -n "Do you want to output the file share information to a file in your current directory? [Y]/N: "
					read outputtofile
					if [ -z "${outputtofile,,}" ] || [ "${outputtofile,,}" = 'y' ]
						 then 
						 filenameright=false
						 skipoutputfile=false
						 while [ $filenameright = false ] && [  $skipoutputfile = false ]
						 do
							  echo -n "Please provide the file name. This file under the current working directory will be created to store the file share information: "
							  read filename
							   if [ -z "$filename" ] 
									then
									echo -n "File name cannot be empty"
							   else
									#filename="$PWD/$filename"
									if [ -e "$filename" ]
										 then
										 echo -n "$filename already exists. [R]-retry/Q-quit"
										 read fileoutput
										  if [ "${fileoutput,,}" = 'q' ]
											   then
											   skipoutputfile=true
										  fi
									else
										 filenameright=true
									fi
							   fi
						 done
						 if [ $filenameright = true ]
							  then
							  cd
							  echo "Created date time:$(date)" >> $filename
							  echo "Subscription name:$sub" >> $filename
							  echo "Storage account name:$sa" >> $filename
							  echo "File share name:$sharename" >> $filename
							  echo "File share information output to $filename. Share it with your team members who want to mount it to their virtual machines. "
						 fi
					fi
			   fi  
		fi  
fi

