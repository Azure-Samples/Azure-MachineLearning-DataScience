#!/bin/bash

#Copy ProjectTemplate and Utilities folder to GroupProjectTemplate and GroupUtilities folder

TDSP_local_copy_linux() {
	echo -n "Please input the full path to $1 (source directory): "
	read src
	echo -n "Please input the full path to $2 (destination directory): "
	read dest

	validpath1=false
	while [ $validpath1 = false ]
	do
		#SourceDirectory=$PWD/$src
		SourceDirectory=$src
		SourceDirectory_git=$SourceDirectory"/.git"
		if [ -d "$SourceDirectory" ] && [ -d "$SourceDirectory_git" ]
			then
			validpath1=true
		else 
			echo "$src is not a valid git repository. Please try it again"
      			exit 1
		fi	
	done

	validpath2=false
	while [ $validpath2 = false ]
	do
		#DestinationDirectory=$PWD/$dest
		DestinationDirectory=$dest
		DestinationDirectory_git=$DestinationDirectory"/.git"
		if [ -d "$DestinationDirectory" ] && [ -d "$DestinationDirectory_git" ]
			then
			validpath2=true
		else 
			echo "$dest is not a valid git repository. Please try it again"
    			exit 1
		fi	
	done

	#SourceDirectory=$PWD/$src
	#DestinationDirectory=$PWD/$dest

	cd $SourceDirectory
	git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)
	cd ../
}

select_your_role() {
	if [ "$1" -eq 1 ]
	 then
			reponame1='ProjectTemplate repository from Microsoft TDSP team'
			reponame2='Your GroupProjectTemplate repository'
			reponame3='Utilities repository from Microsoft TDSP team'
			reponame4='Your GroupUtilities repository'
			TDSP_local_copy_linux "$reponame1" "$reponame2"
			TDSP_local_copy_linux "$reponame3" "$reponame4"

	elif [ "$1" -eq 2 ]
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
}

select_your_role "$1"
