#!/bin/bash

# ask user input
#echo -n "Input the VSTS server name: ";
#read server


echo -n "Select your role in your team: 1-team lead; 2-project-lead; 3-project team member: "
read role
echo

echo " You typed [$role]"
echo

if [ -z "$role" ] ||  ((  "$role" > 3 )) 
 then
 role=2
 echo "You role is set to $role "
fi

#echo "Now your role is set to $role "
#echo

if [ $role -eq 2 ]
 then 
 name1='team repository'
 name2='project repositor'
elif [ $role -eq 1 ]
 then 
 name1='general repository'
 name2='team repository'
else
 name1='project repository'
fi
echo "name1 is $name1"
echo
echo "name2 is $name2"
echo



if [ $role -eq 1 ]
 then
 echo -n "Do you want to set up your team repository on Visual Studio Team Services (VSTS)? Y/N "
 read vstsyesorno
elif [ $role -eq 2 ]
 then
 echo -n "Do you want to set up your project repository on Visual Studio Team Services (VSTS)? Y/N "
 read vstsyesorno
else
 echo -n "Do you want to clone your project repository on your machine (VSTS)? Y/N "
 read vstsyesorno
fi


vstsyesorno2=${vstsyesorno,,}

if [ -z "$vstsyesorno2" ] || [ "$vstsyesorno2" = 'y' ]
 then 
 echo -n "Input the VSTS server name: ";
 read server

 prompt1="Input the name of the $name1 : "
 prompt2="Input the name of the $name2 : "
 
 echo -n $prompt1
 read generalreponame
 echo -n $prompt2
 read teamreponame

 generalrepourl="ssh://$server@$server.visualstudio.com/_git/$generalreponame"
 #teamrepourl="ssh://$server@$server.visualstudio.com/_git/$teamreponame"

 if [ $role -eq 1 ]
  then 
  teamrepourl="ssh://$server@$server.visualstudio.com/_git/$teamreponame"
 elif [ $role -eq 2 ]
  then
  teamrepourl="ssh://$server@$server.visualstudio.com/$generalreponame/_git/$teamreponame"
 else
  generalrepourl="ssh://$server@$server.visualstudio.com/$generalreponame/_git/$teamreponame"
 fi


 if [ $role -lt 3 ]
  then
  #prompt1="Input the name of the $name1 : "
  #prompt2="Input the name of the $name2 : "
  #echo -n $prompt1
  #read generalreponame
  #echo -n $prompt2
  #read teamreponame
  #generalrepourl="ssh://$server@$server.visualstudio.com/_git/$generalreponame"
  #teamrepourl="ssh://$server@$server.visualstudio.com/_git/$teamreponame"
  echo "URL of the $name1 is " $generalrepourl
  echo
  echo "URL of the $name2 is " $teamrepourl
  echo
 else
  #prompt1="Input the name of the $name1 : "
  #echo -n $prompt1
  #read generalreponame
  #generalrepourl="ssh://$server@$server.visualstudio.com/_git/$generalreponame"
  echo "URL of the $name1 is  $generalrepourl "
 fi


 #Use SSH key to authenticate
 echo "SSH key is being generated, press enter 3 times" 
 ssh-keygen
 echo "Copy the following string and add a new SSH public key in https://$server.visualstudio.com/_details/security/keys"
 cd 
 cat .ssh/id_rsa.pub

 function pause(){
    read -p "$*"
 }

 pause 'If you are done with adding SSH public keey, press [Enter] key to continue...'


 echo "Start cloning the $name1 repository..."
 echo
 echo "You might be asked to input your credentials..."
 echo


 rootdir="$PWD"

 echo "Start cloning $name1 ... "
 echo
 git clone $generalrepourl
 echo "$name1 cloned."
 echo

 if [ $role -lt 3 ]
  then
  echo "Start cloning $name2 ..."
  echo
  echo "Currently it is empty. You need to determine the content of it ... "
  echo
  git clone $teamrepourl
  echo "$name2 cloned."
 fi


 if [ $role -lt 3 ]
  then
  echo "Copying the entire directory in $rootdir/$generalreponame except .git directory to $rootdir/$teamreponame..." 
  SourceDirectory=$rootdir/$generalreponame
  DestinationDirectory=$rootdir/$teamreponame

  if [ -d "$DestinationDirectory" ] 
   then
   echo "$DestinationDirectory exists !"
   echo
   echo -n "Do you want to overwrite the $DestinationDirectory? Y/N "
   read overwriteornot 
  fi
  overwriteornot2=${overwriteornot,,}
 
  if [ -z "$overwriteornot2" ] || [ "$overwriteornot2" = 'y' ]
   then
   cd $SourceDirectory
   git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)
   copied='y'
  fi
  
  if [ "$copied" = 'y' ]
   then
   echo "$name1 copied to the $name2 on your disk."
   echo
  fi
  
  echo "Change to the $name2 directory $DestinationDirectory"
  echo
  
  cd $DestinationDirectory
  echo -n "Input If you are ready to commit the $name2, enter Y. Otherwise, go to change your $name2 and come back to enter Y to commit: "
  read commitornot
  commitornot2=${commitornot,,}
 
  if [ "$commitornot2" = 'y' ]
   then
   git add .
   username=$(git config user.name)
   email=$(git config user.email)
   
   if [ -z "$username" ]
    then
    echo -n "For logging purpose, input your name: "
    read user
    git config --global user.name $user
   fi
   
   if [ -z "$email" ]
    then
    echo -n "For logging purpose, input your email: "
    read useremail
    git config --global user.email $useremail
   fi
  
   git commit -m"changed the $name2  directory"
   git push --set-upstream origin master
  
  else
   echo -n "I do not understand your input. Please commit later by yourself using the following commands in sequence."
   echo
   echo -n "These commands need to be submitted when you are in $DestinationDirectory"
   echo
   echo -n "git add ."
   echo
   echo -n "git config --global user.name <your name>"
   echo
   echo -n "git config --global user.email <your email address>"
   echo
   echo -n "git commit -m'This is a commit note'"
   echo
   echo -n "git push"
   echo
  fi
 fi
fi


#install jq to process json file
#sudo -i
#yum install jq

#git clone https://github.com/stedolan/jq.git
#cd jq
#autoreconf -i
#./configure --disable-maintainer-mode
#make
#sudo make install


#Authenticate to Azure
if [ $role -lt 3 ]
 then
 
 if [ $role -eq 1 ]
  then
  echo -n "Do you want to create an Azure file share service for your team? Y/N "
  read createornot
 else
  echo -n "Do you want to create an Azure file share service for your project? Y/N "
  read createornot
 fi
 
 createornot2=${createornot=,,}
 
 if [ -z "$createornot2" ] || [ "$createornot2" = 'y' ]
  then 
  azure config mode arm
  loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
 
  if [ "$loginstat" = "False" ]
   then
   # Login to your Azure account
   echo "Follow directions on screen to login to your Azure account"
   azure login
  fi
 
  #azure account list
  #echo -n "Enter Subscription Name from above list: "
  #read sub
  
  subnameright=false
  quitornot=false
    
  azure account list --json > acctlist.json
  num_sub=$(jq '.| length' acctlist.json)
  sublist=$(cat acctlist.json | jq '.[] .name' --raw-output| cat -n) 
 
  while [ "$subnameright" = true ] && [ "$quitornot" = true ]
  do
   #sublist=$(cat acctlist.json | jq '.[] .name' --raw-output| cat -n)
   echo "$sublist"
   echo -n "Which subscription do you want to use? "
   read subnbr
  
   if [ $subnbr -gt 0 ] && [ $subnbr -le $num_sub ]
    then
    let subnbr2=subnbr-1
    sub=$(cat acctlist.json | jq  '.['$subnbr2'] .name' --raw-output)
    echo "$sub is selected"  
    echo
    echo -n "Type in Y to continue and N to reselect "
    read selectedright
    selectedright2=${selectedright,,}

    if [ -z "$selectedright2" ] || [ "$selectedright2" = 'y' ]
     then
     subnameright=true
    fi

    if [ "$subnameright" = false ]
     then
     echo -n "The number you entered is out of bound. R -retry/Q -quit"
     read quitornotask
     quitornotask2=${quitornotask,,}

     if [ -z "$quitornotask2" ] || [ "$quitornotask2" = 'q' ]
      then echo -n "Creating Azure file share service quit."
      quitornot=true
     fi
    fi
   fi
  done


  if [ "$subnameright" = true ]
   then
   # Set the default subscription where we will create the share
   azure account set "$sub"
  
   #echo -n "Enter storage account name where share is created: "
   #read sacct
  
   echo "Getting the list of storage accounts under subscription $sub"
   # Choose from existing storage account
   azure storage account list --json > storlist.json
   storlist=$(cat storlist.json | jq '.[] .name' --raw-output | cat -n)
   echo "$storlist"
  
   azure group list --json > grplist.json
   grplist=$(cat grplist.json | jq '.[] .name' --raw-output | cat -n)
   #echo "$grplist"
   
   echo -n "Do you want to create a new storage storage account for your Azure file share? Y/N "
   read createornotsa
   createornotsa2=${createornot,,}
   saretryornot='r'
   if [ -z "$createornot2" ] || ["$createornot2" = 'y' ]
    then
    havegoodsaname=false
    saretry=true
    #loc='southcentralus'    
    while [ "$havegoodsaname" = true ] && [ "$saretry" = true ]
    do
     echo -n "Enter the storage name to create (only accept lower case letters and numbers): "
     read sa0
     sa=${sa0,,}
    
     rg=$(cat storlist.json | jq '.[] | select (.name == "'$sa'" )' | jq ' .resourceGroup' --raw-output)
     storlist2=$(cat storlist.json | jq '.[] .name' --raw-output)
     if [[ $storlist2 =~ $sa ]]
      then
      echo -n " Storage account already exists. R-retry/U-use/Q-quit" 
      read saretryornot
      saretryornot2=${saretryornot,,}

      if [ "$saretryornot2" = 'q' ]
       then 
       saretry=false   
      elif [ "$saretryornot2" = 'u' ]
       then
       echo -n "You choose to use an existing storage account $sa. Y-continue/R-retry"
       read useexisting
       useexisting2=${useexisting,,}
        if [ -z "$useexisting2" ] || ["$useexisting2" = 'y' ]
         then 
         havegoodsaname=true
         echo -n "Existing storage $sa will be used. Its resource group is $rg. "
        fi
      fi
     else
      echo -n "Storage account $sa will be created ..."
      echo -n "You need to select the resource group name under which the storage account will be created."
     
      rgvalid=false 
      azure group list --json > grplist.json
      grplist=$(cat grplist.json | jq '.[] .name' --raw-output | cat -n)
      echo "$grplist"
      
      while [ "$rgvalid" = true ]
      do
       num_rg=$(jq '.| length' grplist.json)
       echo -n "Enter the index of resource group you want to use: 0-New/1-$num_rg -use existing ones " 
       read grpnbr
       if [ "$grpnbr" = 0 ]
        then
        echo -n "Please input the name of a new resource group to create (only allows lower cae letters, numbers,underline, and hyphen)"
        read rgname0
        rgname=${rgname0,,}
        grplist2=$(cat grplist.json | jq '.[] .name' --raw-output)
        if [[ $grplist2 =~ $rgname ]] 
         then 
         echo -n "Resource group $rgname exists. U-use/R-retry"
         read useexisting
         useexisting2=${useexisting,,}
         if [ -z "$useexisting2" ] || [ "$useexisting2" = 'u' ]
          then
          rgvalid=true 
        else
         rgvalid=true
        fi
       else
        if [ "$grpnbr" -gt 0 ] && [ "grpnbr" -le $num_rg ]
         then
         let grpnbr2=grpnbr-1
         grp=$(cat grplist.json | jq  '.['$grpnbr2'] .name' --raw-output)
         echo -n "$grp is selected. Y-continue/R-retry"
         read continue
         continue2=${continue,,}
         if [ -z "$continue2" ] || [ "$continue2" = 'y' ]
          then
          rgvalid=true
        else
          echo -n "Selected index of existing resource group out of bounds. Retry..."
        fi
       fi
      fi
     fi 
     done

      havegoodsaname=true
      grplist2=$(cat grplist.json | jq '.[] .name' --raw-output)
      if [[ $grplist2 =~ $rgname ]]
       then
       echo -n "Start creating storage account $sa under resource group $rgname. "
      else 
       echo -n "Start creating resource group $rgname. "
       azure group create $rgname
       echo -n "Start creating storage account $sa under resource group $rgname. "
       azure storage account create $sacct -g $rgname
      fi
     fi
  
  else
   validexistingsaname=false
   saretry=true
   azure storage account list --json > storlist.json
   num_stor=$(jq '.| length' storlist.json)
   while [ "$validexistingsanme" = true ] && [ "$saretry" = true ]
   do
    echo -n "Enter the index of the storage account to use (1 - $num_stor )"
    read saindex
    if [ "$saindex" - gt 0 ] && [ "$saindex" -le num_stor ]
     then
     let saindex2=saindex-1
     sa=$(cat storlist.json | jq  '.['$saindex2'] .name' --raw-output)
     rg=$(cat storlist.json | jq  '.['$saindex2'] .resourceGroup' --raw-output)
     echo -n "You selected storage account $sa. Y-continue/N-reselect"
     read saconfirm
     saconfirm2=${saconfirm,,}
     if [ -z "$saconfirm2" ] || [ "$saconfirm2" = 'y' ]
      then
      echo -n "Stoage account $sa is selected. Its resource group is $rg. "
      validexistingsaname=true
     fi  
    else
      echo -n "Selected index of storage account out of bounds. R-retry/Q-quit"
      read saretryornot
      saretryornot2=${saretryornot,,}
      if [ "$saretryornot2" = 'q' ]
       then
       saretry=false
       echo -n "Quitting ..." 
      fi
    fi  
   done 
  #fi

  azure storage account set -g $rg  $sa

  validsharename=false
  quitcreateshare=false
  while [ "$validsharename" = true ] && [ "$quitcreateshare" = true ]
  do
   echo -n "Enter the name of the file share service to create (lower csase characters, numbers, and - are accepted"
   read sharename0
   if [ -z "$sharename0" ]
    then
    echo -n "You entered an empty file share name. R-retry/Q-quit"
    read retrysharename
    retrysharename2=${retrysharename,,}
    if [ "$retrysharename2" = 'q' ]
     then 
     quitcreateshare=true
    fi
   else
    sharename=${sharename0,,}
    if [ "$sharename" ne "$sharename0" ] 
     then
     echo "Invalid file share name '$sharename0' converted to '$sharename'"
    else
     validsharename=true 
    fi
   fi
  done 

  if [ "$validsharename" = true ]
   then
   x=`azure storage account connectionstring show $sa -g $rg --json`
   # Extract the storage connectionstring with the keys
   y=`echo $x | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["string"])'`
   export AZURE_STORAGE_CONNECTION_STRING=$y
   azure storage share create $sharename
   azure storage directory create $sharename  -p 'data'
   echo -n "An Azure file share service created. It can be later mounted to the Azure virtual machine screated for your team projects. "
   echo
   echo -n "Please keep a note for the information of the Azure file share service. It will be needed in the future when mounting it to Azure virtual machines."
   echo
   echo -n "Do you want to output the file share information to a file in your current directory? Y/N"
   read outputtofile
   outputtofile2=${outputtofile,,}
   if [ -z "$outputtofile2" ] || [ "$outputtofile2" = 'y' ]
    then 
    filenameright=false
    skipoutputfile=false
    while [ "$filenameright" = true ] && [ "$skipoutputfile" = true ]
    do
     echo -n "Please provide the file name. This file under the current working directory will be created to store the file share information."
     read filename
      if [ -z "$filename" ] 
       then
       echo -n "File name cannot be empty"
      else
       filename="$PWD"/$filename
       if [ -d "$filename" ]
        then
        echo -n "$filename already exists. R-retry/Q-quit"
        read fileoutput
        fileoutput2=${fileoutput,,}
        if [ "$fileoutput" = 'q' ]
         then
         skipoutputfile=true
        fi
       else
        filenameright=true
       fi
      fi
    done
    if [ "$filenameright" = true ]
     then
     echo "Created date time : $(date) " >> $filename
     echo "Subscription name : $sub " >> $filename
     echo "Storage account name : $storname " >> $filename
     echo "File share name : $sharename " >> $filename
     echo -n "File sahre information output to $filename. Share it with your team members who want to mount it to their virtual machines. "
    fi
   fi
 fi




function mountfileservices {
  echo -n " Start getting the list ofsubscriptions under your Azure account..."
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
  echo " Here are the subscriptions :"
  echo
  echo "$sublist"
  echo
  echo -n "Do you have a file with the information of the file share you want to mount? Y/N "
  read inputfileyesorno
  inputfileyesorno2=${inputfileyesorno,,}
  if [ "$inputfileyesorno2" != 'n' ]
   then
   inputfileyesorno='y'
  fi

  sub='NA'
  sa='NA'
  sharename='NA'

  if [ -z "$inputfileyesorno" ] || [ "$inputfileyesorno" = 'y' ]
   then
   inputfilequit=false
   inputfileright=false
   while [ "$inputfilequit" = true ] && [ "inputfilequit" = true ]
   do
    echo -n "Please provide the name of the file with the information of the file share you want to mount"
    read filename
    if [ -z "$filename" ]
     then 
     echo -n "File name cannnot be empty. R-retry/S-skip."
     read retryinput
     retryinput2=${retryinput,,}
     if [ "$retryinput2" = 's' ]
      then
      inputfilequit=true
     fi
    else
     if [ -d "$filename" ]
      then
      echo -n "File does not exist. R-retry/S-skip" 
      read retryinput
      retryinput2=${retryinput,,}
      if [ "$retryinput2" = 's' ]
       then 
       inputfilequit=true
      fi
     else
      inputfileright=true
     fi
    fi
   done
   if [ "$inputfileright" = true ]
    then
    sub=$(sed -n -e 's/^.*Subscription name: //p' $filename)
    sa=$(sed -n -e 's/^.*Storage account name: //p' $filename)
    sharename=$(sed -n -e 's/^.*File share name: //p' $filename)
    if [ "$sub" = 'NA' ] || ["$sa" = 'NA' ] || [ "$sharename" = 'NA' ]
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
 while [ "$subnameright" = true ] && [ "$quitornot" = true ]
 do
   if [ "$sub" = 'NA' ]
    then
    echo -n "Enter the subscription name where the Azure file share service has been created"
    read sub
   fi
   azure account list --json > acctlist.json
   sublist=$(cat acctlist.json | jq '.[] .name' --raw-output)
   if [[ $sublist =~ $sub ]]
    then
    subnameright=true
   else
    echo -n "Enter the subscription name where Azure file share service has been created: R-retry/Q-quit"
    read quitornotask
    quitornotask2=${quitornotask2,,}
    sub='NA'
    sa='NA'
    sharename='NA'
    if ["$quitronotask2" = 'q' ]
     then
     echo -n "Mounting Azure file share quit. "
     quitornot=true
    fi
   fi
 done

 if [ "$subnameright" = true ]
  then
  retrycount=0
  getstoragesucceed=false
  azure account list --json >acctlist.json
  num_sub=$(jq '.| length' acctlist.json)
  azure account set "$sub"
  echo -n "Start getting the list of storage accounts under your subscription $sub "
  while [ "$getstoragesucceed" = true ] && [ "$retrycount" -lt 10 ]
  do
   azure storage account list --json > storlist.json
   num_stor=$(jq '.| length' storlist.json)
   if [ "$num_stor" -gt 0 ]
    then
    getstoragesucceed=true
   fi
   if [ "$getstoragesucceed" = true ]
    then
    let retrycount=retrycount+1
    echo -n "Trial $retrycount failed to get storage account list from your subscription $sub. Wait for 1 second to try again. "
    sleep 1
   fi
  done
  if [ "$getstoragesucceed" = true ] && [ "$retrycount" -eq 10 ]
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
   goodsaname=false
   quitornot=false
   while [ "$goodname" = true ] && [ "$quitornot" = true ]
   do
    if ["$sa" = 'NA' ]
     then
     echo -n "Enter the index of the storage account name where your Azure file share you want to mount is created: "
     read saindex
     if [ "$saindex" -gt 0 ] && [ "$saindex" -le $num_stor ]
      then
      let saindex2=saindex-1
      sa=$(cat storlist.json | jq  '.['$saindex2'] .name' --raw-output)
      rg=$(cat storlist.json | jq  '.['$saindex2'] .resourceGroup' --raw-output) 
      goodname=true
     else
      echo -n "Index out of bounds (1 - $num_stor ) R-retry/Q-quit "
      read quitsa
      quitsa2=${quitsa,,}
      if [ "$quitsa2" = 'q' ]
       then
       quitornot=true
      fi
     fi
    else
     storageaccountnames2=$(cat storlist.json | jq '.[] .name' --raw-output)
     if [[ ! $storageaccountnames =~ $sa ]]
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
   
   if ["$goodname" = true ]
    then
    sharenameexist=false
    quitnewsharename=false
    #storkey 
    sharenameright=false
    quitornot=false
    while [ "$sharenameexist" = true ] && [ "$quitenewsharename" = true ]
    do
     while [ "$sharenameright" = true ] && [ "$quitornot" = true ]
     do
      if [ "$sharename" = 'NA' ]
       then
       echo -n "Enter the name for the file share to mount (lower case only): "
       read sharename
       sharename=${sharename,,} 
      elif [ -z "sharename" ]
       then 
       echo -n "File share name cannot be empty. R-retry/Q-quit. "
       read quitornotanswer
       if [ "${quitornotanswer,,}" = 'q' ]
        then
        quitornot=true
       fi
      else
       sharenameright=true
      fi
     done
     
     if [ "$sharenameright" = true ]
      then
      drivenameright=false
      existingdisks=$(df -h)
      existingdisknames=$(df -h | cut -d" " -f1 | tail -n+2)  
      echo -n "Existing disk names are: "
      echo
      echo -n "$existingdisks" 
      echo
      quitdrivename=false
      while [ "$drivenameright" = true ] && [ "$quitedrivename" = true ]
      do
       echo -n "Enter the name of the drive to be added to your virtual machine. This name should be diferent from the disk names your virtual machine has."
       read drivename
       drivelist=$(df -h | rev | cut -d" " -f1 | rev)
       if [[ $drivelist =~ $drivename ]]
       #if echo "$sublist" | grep -q "$sub" ; then echo "matched" ;else echo "not matched"; fi;
        then
        echo -n "The disk drive $drivename you want to mount the file sahre already exists. R-retry/Q-quit"
        read inputnewdrive
        if [ "${inputnewdrive,,}" = 'q' ]
         then
         quitdrivename=true
        fi
       else
        drivenameright=true
       fi
      done
      
      if [ "$drivenameright" = true ]
       then
       echo -n "File share $sharename will be mounted to your virtual machine as drive $drivename "
       k=`azure storage account keys list  $sa -g $rg --json |  python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["key1"])'`
       sudo mkdir -p /$drivename
       sudo mount -t cifs //$sa.file.core.windows.net/$sharename /$drivename -o vers=3.0,username=$sa,password=$k,dir_mode=0777,file_mode=0777
       sharenameexist=true
      fi
     fi


#Mount share files to Linux DSVM

if [ $role -gt 0 ]
 then
 echo -n "Do you want to mount an Azure File share service to your Azure Virtual Machine? Y/N "
 read mountornot
 mountornot2=${mountornot,,}
 # echo "mountornot2 is $mountornot2"
 if [ -z "$mountornot2" ] || [ "$mountornot2" = 'y' ]
  then
  mountfileservices
  others=1
  while [ $others -eq 1 ]
  do
   echo -n "Do you want to mount other Azure File share services? Y/N "
   read mountornot_other
   mountornot_other2=${mountornot_other,,}
   #echo "mountornot_other2 is $mountornot_other2"
   if [ -z "$mountornot_other2" ] || [ "$mountornot_other2" = 'y' ]
   #if [ "$mountornot_other" -eq 1 ]
    then
    mountfileservices
   else
    others=0
    #echo "others is $others"
   fi
  done
 fi
fi

