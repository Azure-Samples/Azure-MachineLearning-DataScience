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
 
  while [ subnameright = true ] && [ quitornot = true ]
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
   if [ -z "$createornot2" ] || ["createornot2" = 'y' ]
    then
    havegoodsaname=false
    saretry=true
    



  #### echo -n "Which storage account do you want to use? " ;read stornbr;let stornbr2=stornbr-1;
  #### stor=$(cat storlist.json | jq  '.['$stornbr2'] .name' --raw-output)
  #### echo "$stor is selected"


  # Choose from existing resource group
  azure group list --json > grplist.json
  grplist=$(cat grplist.json | jq '.[] .name' --raw-output | cat -n)
  echo "$grplist"
  echo -n "Which resource group do you want to use? " ;read grpnbr;let grpnbr2=grpnbr-1;
  grp=$(cat grplist.json | jq  '.['$grpnbr2'] .name' --raw-output)
  echo "$grp is selected"


  #echo -n "Enter resource group name : "
  #read rgname
  
  echo -n "Create a new storage account? "
  read answer
 
  if echo "$answer" | grep -iq "^y"
   then
   #Create storage account
   azure storage account create $sacct -g $rgname
  fi
 
  #Create storage account
  x=`azure storage account connectionstring show $stor -g $grp --json`
  # Extract the storage connectionstring with the keys
  y=`echo $x | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["string"])'`
  export AZURE_STORAGE_CONNECTION_STRING=$y

  echo -n "Enter the file share to create: "
  read shar
  
  # Create a mountable share
  azure storage share create $shar
  echo -n "Enter the directory to create in the file share: "
  read directory
  
  # Create an empty directory
  azure storage directory create $shar  $directory
 fi
fi



function mountfileservices {
 #azure config mode arm
 #loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
 #if [ "$loginstat" = "False" ]
 # then
 # # Login to your Azure account
 # echo "Follow direction on screen to login to your Azure account"
 # azure login
 #fi

 #echo -n "Enter storage account name where share was created: "
 #read sacct
 #echo -n "Enter resource group name : "
 #read rgname
 k=`azure storage account keys list  $stor -g $grp --json |  python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["key1"])'`
 
 #echo -n "Enter the file share to mount: "
 #read shar
 #echo -n "Enter the directory where to mount the share : "
 #read directory
 sudo mkdir -p /$directory
 sudo mount -t cifs //$stor.file.core.windows.net/$shar /$directory -o vers=3.0,username=$stor,password=$k,dir_mode=0777,file_mode=0777
}



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

