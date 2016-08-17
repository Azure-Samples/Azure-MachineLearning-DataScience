#!/bin/bash

#Copy ProjectTemplate and Utilities folder to GroupProjectTemplate and GroupUtilities folder


echo -n "Select your role in your team: 1-group manager;[2]-team lead;3-project lead: "
read role
echo

if [ -z "$role" ] ||  ((  "$role" > 3 )) 
 then
 role=2
 echo "You role is set to $role "
fi


TDSP_local_copy_linux() {

echo -n "Please input the local path to $1 (source directory): "
read src
echo -n "Please input the local path to $2 (destination directory): "
read dest


SourceDirectory=$PWD/$src
DestinationDirectory=$PWD/$dest
cd $SourceDirectory
git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)
cd ../

}



if [ $role -eq 1 ]
 then 
	reponame1='ProjectTemplate repository from Microsoft TDSP team'
	reponame2='Your GroupProjectTemplate repository'
	reponame3='Utilities repository from Microsoft TDSP team'
	reponame4='Your GroupUtilities repository'
	TDSP_local_copy_linux "$reponame1" "$reponame2"
	TDSP_local_copy_linux "$reponame3" "$reponame4"
	
elif [ $role -eq 2 ]
 then 
	reponame1='Your GroupProjectTemplate repository'
	reponame2='Your TeamProjectTemplate repository'
	reponame3='Your GroupUtilities repository'
	reponame4='Your TeampUtilities repository'

	TDSP_local_copy_linux "$reponame1" "$reponame2"
	TDSP_local_copy_linux "$reponame3" "$reponame4"
	
else
	reponame1='Your TeamProjectTemplate repository'
	reponame2='Your Project repository'
	
	TDSP_local_copy_linux "$reponame1" "$reponame2"
fi
