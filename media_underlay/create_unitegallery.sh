#!/bin/bash

path="${1%/}"
# echo "path: '$path'"
cd "$path" || { >&2 echo "error! no existe '$path'"; exit 1; }
[[ -d "300px" ]] || mkdir "300px" || { >&2 echo "error! no se puedo crear '300px'"; exit 1; }
[[ -d "1280px" ]] || mkdir "1280px" || { >&2 echo "error! no se puedo crear '1280px'"; exit 1; }

gallery_name=$( basename "$path")

echo "[[!field unite_gallery=\"tiles\" gallery_1=\"$gallery_name\"]]"
echo -e "\n"

echo "<div id=\"$gallery_name\" class=\"unite-gallery tiles\" style=\"display:none;\">"

shopt -s nullglob
for file in *.jpg *.png *.jpeg; do
   if [[ ! -f "300px/$file" ]]; then
	   convert "$file" -resize 300 "300px/$file" || { >&2 echo "error! resize a 300px falló con '$file'"; exit 1; }
	fi
   if [[ ! -f "1280px/$file" ]]; then
	   convert "$file" -resize 1280x1280 "1280px/$file" || { >&2 echo "error! resize a 1280x1280px falló con '$file'"; exit 1; }
	fi
   echo "<img alt=\"\" src=\"/$path/300px/$file\""
   echo "   data-image=\"/$path/1280px/$file\""
	echo "   data-description=\"\">"
done

echo "</div>"