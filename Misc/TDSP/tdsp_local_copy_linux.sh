#!/bin/bash

#Copy ProjectTemplate and Utilities folder to GroupProjectTemplate and GroupUtilities folder

function TDSP_local_copy_linux {

echo -n "What is your source folder?"
read src
echo -n "What is your destination folder?"
read dest

SourceDirectory=$PWD/$src
DestinationDirectory=$PWD/$dest
cd $SourceDirectory
git archive HEAD --format=tar | (cd $DestinationDirectory; tar xvf -)
cd ../

}
#ProjectTemplate --> GroupProjectTemplate
TDSP_local_copy_linux
#Utilities --> GroupUtilities
TDSP_local_copy_linux
