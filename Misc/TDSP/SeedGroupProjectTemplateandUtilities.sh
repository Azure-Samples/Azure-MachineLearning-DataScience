			#Copy ProjectTemplate folder to GroupProjectTemplate folder
			src="ProjectTemplate"
			dest="GroupProjectTemplate"
			SourceDirectory=$PWD/$src
			DestinationDirectory=$PWD/$dest
			cd $SourceDirectory
			git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)
			cd ../

			# Copy Utilities folder to GroupUtilities folder
			src="Utilities"
			dest="GroupUtilities"
			SourceDirectory=$PWD/$src
			DestinationDirectory=$PWD/$dest
			cd $SourceDirectory
			git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)
			cd ../ 
