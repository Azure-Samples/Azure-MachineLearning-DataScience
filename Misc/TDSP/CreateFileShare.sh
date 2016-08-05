
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
