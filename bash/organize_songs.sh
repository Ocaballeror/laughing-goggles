#!/bin/bash

# I use this script to automatically organize the "Songs" folder for clone hero, since all the 
# subdirectories there will follow a specific format.
#
# Run it in a directory where songs are stored in separate folders and have a song.ini file
# to reorganize all the directories in this format:
#
# artist/album/song/
#
# NOTES:
# If the new directory already exists, the current one is marked as a duplicate and immediately
# deleted.
#
# If any of the parameters can't be determined from the song.ini file, it defaults to "Unknown". 
# Make sure to check for any directories with this name to manually name them.


process() {
	name=$(echo "$@" | tr -d "',|;/\\n\\r")
	python3 -c "print('$name'.strip().title())" || echo "$name" >> errlog
}

find . -type d | while read -r d; do
	[ -d "$d" ] || continue
	if ! [ -f "$d/song.ini" ]; then
	   if [ -f "$d/Song.ini" ]; then
		   mv "$d/Song.ini" "$d/song.ini"
	   else
	   	   continue
	   fi
   fi

	find "$d" -type f -name "*.ini" -exec dos2unix {} \; >/dev/null 2>&1 || continue
	title=$(awk -F= 'BEGIN{IGNORECASE=1} /^name *=/ {print $2}' "$d/song.ini")
	album=$(awk -F= 'BEGIN{IGNORECASE=1} /^album *=/ {print $2}' "$d/song.ini")
	artist=$(awk -F= 'BEGIN{IGNORECASE=1} /^artist *=/ {print $2}' "$d/song.ini")

	title=$(process "$title")
	album=$(process "$album")
	artist=$(process "$artist")
	echo "$artist - $album - $title"

	if ! [ "$album" ]; then
		album="Unknown"
	fi
	if ! [ "$artist" ]; then
		artist="Unknown"
	fi
	if ! [ "$title" ]; then
		title="Unknown"
	fi

	if [ -d "$artist/$album/$title" ] ; then
		if ! [ "$d" -ef "$artist/$album/$title" ]; then
			echo "DUPLICATE: $title"
			echo "REMOVE: $d"
			rm -rf "$d"
		else
			echo "IGNORE: $title"
		fi
	else
		mkdir -p "$artist/$album"
		mv "$d" "$artist/$album/$title"
		echo "REMOVE: $d"
		rm -rf "$d"
	fi
	
done

echo "DELETING OLD JUNK"
find . -type d -empty -print -delete 
