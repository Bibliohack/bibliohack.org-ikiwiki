#!/bin/bash

REPROCESS_ALL="No"

print_folder_recurse() {
   for i in "$1"/*;do
      if [ -d "$i" ];then
         echo "RECURSION dir: $i"
         echo
         print_folder_recurse "$i"
		elif [ -f "$i" ]; then
			if [[ $i =~ \.jpg$ ]] || [[ $i =~ \.jpeg$ ]] || [[ $i =~ \.png$ ]]; then
				echo "$i"
			   if [[ $i =~ _small\.jpg$ ]] || [[ $i =~ _default\.jpg$ ]]; then
			   	:
			   else
			   	if [[ ! -f "${i}_default.jpg" ]] || [[ "$REPROCESS_ALL" == "Si" ]]
			   	 then
			   	 	# echo "convert '$i' a '${i}_default'";
			   	 	echo "$i"
				      convert "$i" -resize 768x543^ -gravity center -extent 768x543 "${i}_default.jpg" && {
				      	echo "default build OK" 
				      } || { 
				      	>&2 echo "error! resize default en '$i'"
				      	exit 1 
				      }
			   	fi
			   	if [[ ! -f "${i}_small.jpg" ]] || [[ "$REPROCESS_ALL" == "Si" ]]
			   	 then
				   	#	echo "convert '$i' a '${i}_small'";
				   	echo "$i"
				      convert "$i" -resize 300 "${i}_small.jpg" && {
				      	echo "small build OK";
				      } || { 
				      	>&2 echo "error! resize small en '$i'"
				      	exit 1 
				      }
			   	fi
			   fi
			fi
      fi
   done
}

path=""
if [ -d "$1" ]; then
   path="${1%/}"
   echo "path: '$path'"
else
	echo "$1 no es un directorio"
   exit 1
fi

print_folder_recurse "$path"

exit 0
