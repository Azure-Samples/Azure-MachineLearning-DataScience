
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
