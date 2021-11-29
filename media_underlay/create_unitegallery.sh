#!/bin/bash

# bash create_unitegallery.sh uploads/galleries/nombre_galeria/
currentpath=$(pwd)
path="${1%/}"
# echo "path: '$path'"
cd "$path" || { >&2 echo "error! no existe '$path'"; exit 1; }
[[ -d "300px" ]] || mkdir "300px" || { >&2 echo "error! no se puedo crear '300px'"; exit 1; }
[[ -d "1280px" ]] || mkdir "1280px" || { >&2 echo "error! no se puedo crear '1280px'"; exit 1; }

REPROCESS_ALL="No"

gallery_name=$( basename "$path")

echo
echo "[[!field unite_gallery=\"tiles\" gallery_1=\"$gallery_name\"]]"
echo -e "\n"

echo "<div id=\"$gallery_name\" class=\"unite-gallery tiles\" style=\"display:none;\">"

shopt -s nullglob
for file in *.jpg *.png *.jpeg; do
   filename="${file%.*}"
   if [[ ! -f "300px/${filename}.jpg" ]] || [[ "$REPROCESS_ALL" == "Si" ]]; then
	   # convert "$file" -resize 300 -quality 75 "300px/${filename}.jpg" || { >&2 echo "error! resize a 300px falló con '$file'"; exit 1; }
  	   convert "$file" -resize 300x300^ -gravity center -extent 300x300 -quality 75 "300px/${filename}.jpg" || { >&2 echo "error! resize a 300px falló con '$file'"; exit 1; }
	fi
   if [[ ! -f "1280px/${filename}.jpg" ]] || [[ "$REPROCESS_ALL" == "Si" ]]; then
	   convert "$file" -resize 1280x1280 -quality 80 "1280px/${filename}.jpg" || { >&2 echo "error! resize a 1280x1280px falló con '$file'"; exit 1; }
	fi
	description=$( exiftool -s -s -s -charset latin -Caption-abstract $file )
   echo "   <img alt=\"$description\" src=\"/$path/300px/${filename}.jpg\""
   echo "   data-image=\"/$path/1280px/${filename}.jpg\""
	echo "   data-description=\"\">"
done

echo "</div>"

cd $currentpath
ikiwiki --setup ../wiki.setup.yaml || {
	 >&2 echo "error! fallo ikiwiki config"; exit 1; 
}
