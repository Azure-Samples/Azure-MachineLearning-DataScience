#!/bin/bash

# ask user input
echo -n "Input the VSTS server name: ";
read server


echo -n "Select your role in your team: 1-team lead; 2-project-lead; 3-project team member: "
read role
echo

echo " You typed [$role]"
echo

#if [ -z "$role" ] || [ $role -ne 1 ] || [ $role -ne 3 ]
#if [ -z "$role" ] || ( ((  "$role" != 1 )) || (( "$role" != 3 )))
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

if [ $role -lt 3 ]
 then
 prompt1="Input the name of the $name1 : "
 prompt2="Input the name of the $name2 : "
 echo -n $prompt1
 read generalreponame
 echo -n $prompt2
 read teamreponame
 generalrepourl="https://$server.visualstudio.com/_git/$generalreponame"
 teamrepourl="https://$server.visualstudio.com/_git/$teamreponame"
 echo "URL of the $name1 is " $generalrepourl
 echo
 echo "URL of the $name2 is " $teamrepourl
 echo
else
 prompt1="Input the name of the $name1 : "
 echo -n $prompt1
 read generalreponame
 generalrepourl="https://$server.visualstudio.com/_git/$generalreponame"
 echo "URL of the $name1 is  $generalrepourl "
fi


## This method does not work...
#Use SSH key to authenticate
#echo "SSH key is being generated, press enter 3 times" 
#ssh-keygen
#echo "Copy the following string and add a new SSH public key in https://$server.visualstudio.com/_details/security/keys"
#cd 
#cat .ssh/id_rsa.pub



#Installing on Linux using RPM
#https://github.com/Microsoft/Git-Credential-Manager-for-Mac-and-Linux/blob/master/Install.md

#Step 1: Download git-credential-manager-1.7.1-1.noarch.rpm and copy the file somewhere locally.
wget  https://github.com/Microsoft/Git-Credential-Manager-for-Mac-and-Linux/releases/download/git-credential-manager-1.7.1/git-credential-manager-1.7.1-1.noarch.rpm
#Step 2: Download the PGP key used to sign the RPM.
wget  https://java.visualstudio.com/Content/RPM-GPG-KEY-olivida.txt
#Step 3: Import the signing key into RPM's database
sudo rpm --import RPM-GPG-KEY-olivida.txt
#Step 4: Verify the GCM RPM
rpm --checksig --verbose git-credential-manager-1.7.1-1.noarch.rpm
#Step 5: Install the RPM
sudo rpm --install git-credential-manager-1.7.1-1.noarch.rpm
#Step 6: Run the GCM in install mode
git-credential-manager install


echo "Your Git Credential Manager is successfully installed!"
echo

echo "Start cloning the $name1 repository..."
echo
echo "You might be asked to input your credentials..."
echo

#azure login


rootdir="$PWD"


echo "Start cloning $name1 ... "
echo
git clone $generalrepourl


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

 cd $SourceDirectory
 git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)

 echo "$name1 copied to the $name2 on your disk."
 echo
 echo "Change to the $name2 directory $DestinationDirectory"
 echo
 
 cd $DestinationDirectory
 echo -n "Input If you are ready to commit the $name2, enter Y. Otherwise, go to change your $name2 and come back to enter Y to commit..."
 read commitornot
 commitornot2=${commitornot,,}
 
 if [ commitornot2='y' ]
 then
  git add .
  username=$(git config user.name)
  email=$(git config user.email)
  if [ -z "$username" ]
  then
    echo -n "For logging purpose, input your name"
    read user
    git config --global user.name $user
  fi
  if [ -z "$email" ]
  then
    echo -n "For logging purpose, input your email"
    read useremail
    git config --global user.email $useremail
  fi
  git commit -m"changed the team repository directory"
  git push
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


#role=2

if [ $role -lt 3 ]
 then
 
 if [ $role -eq 1 ]
  then
  echo "Do you want to create an Azure file share service for your team? Y/N "
  read createornot
 else
  echo "Do you want to create an Azure file share service for your project? Y/N "
  read createornot
 fi
 
 createornot2=${createornot=,,}
 
 if [ -z "$createornot2" ] || [ createornot2='y' ]
  then 
  azure config mode arm
  loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
 
  if [ "$loginstat" = "False" ]
   then
   # Login to your Azure account
   echo "Follow directions on screen to login to your Azure account"
   azure login
  fi
 
  azure account list
  echo -n "Enter Subscription Name from above list: "
  read sub
  # Set the default subscription where we will create the share
  azure account set "$sub"
  echo -n "Enter storage account name where share is created: "
  read sacct
  echo -n "Enter resource group name : "
  read rgname
  echo -n "Create a new storage account? "
  read answer
 
  if echo "$answer" | grep -iq "^y"
   then
   #Create storage account
   azure storage account create $sacct -g $rgname
  fi
 
  #Create storage account
  x=`azure storage account connectionstring show $sacct -g $rgname --json`
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
 azure config mode arm
 loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
 if [ "$loginstat" = "False" ]
  then
  # Login to your Azure account
  echo "Follow direction on screen to login to your Azure account"
  azure login
 fi

 echo -n "Enter storage account name where share was created: "
 read sacct
 echo -n "Enter resource group name : "
 read rgname
 k=`azure storage account keys list  $sacct -g $rgname --json |  python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["key1"])'`
 
 echo -n "Enter the file share to mount: "
 read shar
 echo -n "Enter the directory where to mount the share : "
 read directory
 sudo mkdir -p /$directory
 sudo mount -t cifs //$sacct.file.core.windows.net/$shar /$directory -o vers=3.0,username=$sacct,password=$k,dir_mode=0777,file_mode=0777
}




#Mount share files to Linux DSVM

if [ $role -gt 1 ]
 then
 echo "Do you want to mount an Azure File share service to your Azure Virtual Machine? Y/N "  
 read mountornot
 mountornot2=${mountornot=,,} 
 if [ -z "$mountornot2" ] || [ mountornot2='y' ]
  then
  mountfileservices
  #others=1
  #while [ $others -eq 1 ]
  #do
  # echo "Do you want to mount other Azure File share services? Y/N "
  # read mountornot_other
  # mountornot_other2=${mountornot_other=,,}
  # if [ -z "$mountornot_other2" ] || [ mountornot_other2='y' ]
  #  then 
  #  mountfileservices
  # else
  #  others=0
  # fi
  #done  
 fi
fi



#azure config mode arm
#loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
#if [ "$loginstat" = "False" ]
# then
# # Login to your Azure account
# echo "Follow direction on screen to login to your Azure account"
# azure login
#fi
#
#echo -n "Enter storage account name where share was created: "
#read sacct
#echo -n "Enter resource group name : "
#read rgname
#k=`azure storage account keys list  $sacct -g $rgname --json |  python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["key1"])'`
#
#echo -n "Enter the file share to mount: "
#read shar
#echo -n "Enter the directory where to mount the share : "
#read directory
#sudo mkdir -p /$directory
#sudo mount -t cifs //$sacct.file.core.windows.net/$shar /$directory -o vers=3.0,username=$sacct,password=$k,dir_mode=0777,file_mode=0777















