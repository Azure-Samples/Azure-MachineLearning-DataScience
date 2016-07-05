#!/usr/bin/bash


#Prerequisite
# 1. Git version is 1.9 or above
# 2. Azure Resource group, Storage Account, and your linux machine are in the same geo- location 


printf " Make sure Git is version 1.9 or higher and\nAzure Resource group, Storage Account, and your Linux DSVM are in the same geo-location\n"

# ask user input
echo -n "Input the VSTS server name: ";
read server;

echo -n "Input the name of the general repository: ";
read generalreponame

echo -n "Input the repo name of your team: "
read teamreponame

#print out keyboard input
echo -n "Your VSTS server name is: " $server 
echo
echo -n "Your general repo name is: " $generalreponame
echo
echo -n "Your team repo name is: " $teamreponame
echo

#create general and team repo URL 
generalrepourl="https://$server.visualstudio.com/_git/$generalreponame"
teamrepourl="https://$server.visualstudio.com/_git/$teamreponame"

#print out repo URLs
echo "URL of the general repository is " $generalrepourl
echo
echo "URL of the team repository is " $teamrepourl
echo


#check Git version, Git version  1.9 or above is needed, uninstall current version and install new one
#http://tecadmin.net/install-git-2-x-on-centos-rhel-and-fedora/

gitversion_text=$(git --version)
gitversion_number=${gitversion_text//[!0-9]/}
gitversion_number2=$(echo "scale=1;$gitversion_number/100" | bc)
min_version=1.9


echo "Your Git version is $gitversion_number2"

if (( ${gitversion_number2%%.*} <  ${min_version%%.*}   || ( ${gitversion_number2%%.*} == ${min_version%%.*} && ${gitversion_number2##*.} < ${min_version##*.} )  ))
then
  echo "Your Git version has to be 1.9 or higher!"
  su
  su -c 'yum remove git.x86_64'
  yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
  yum install gcc perl-ExtUtils-MakeMaker
  cd /usr/src
  wget https://www.kernel.org/pub/software/scm/git/git-2.8.1.tar.gz
  tar xzf git-2.8.1.tar.gz
  cd git-2.8.1
  make prefix=/usr/local/git all
  make prefix=/usr/local/git install
  export PATH=$PATH:/usr/local/git/bin
  source /etc/bashrc
  echo "$(git --version) is installed on your machine! "
else
  echo "Your Git version is up to date!"
fi


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

echo "Start cloning the general repository..."
echo
echo "You might be asked to input your credentials..."
echo

azure login

git clone $generalrepourl

echo "General repository cloned"
echo
echo "Start cloning your team repository..."
echo
echo "Currently it is empty. You need to determine the content of it..."
echo

git clone $teamrepourl

echo "Team repository cloned"
echo 

rootdir="$PWD"

echo "Copying the entire directory in $rootdir/$generalreponame except .git directory to $rootdir/$teamreponame..."

SourceDirectory=$rootdir/$generalreponame
DestinationDirectory=$rootdir/$teamreponame

cd $SourceDirectory
git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)

echo "General repository copied to the team repository on your disk."
echo
echo "Change to the team repository directory $DestinationDirectory"
echo

cd $DestinationDirectory


echo -n "Input If you are ready to commit the new team repository, enter Y. Otherwise, go to change your team repository and come back to enter Y to commit..."
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


echo "Make sure the resource group, storage account, and your linux machine are in the same location!"
echo

#Create File share
azure config mode arm
loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
if [ "$loginstat" = "False" ] ; then
# Login to your Azure account
echo "Follow direction on screen to login to your Azure account"
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

if echo "$answer" | grep -iq "^y" ;then
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


#Mount file
azure config mode arm
loginstat=`azure account list --json | python -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj)>0)'`
if [ "$loginstat" = "False" ] ; then
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


