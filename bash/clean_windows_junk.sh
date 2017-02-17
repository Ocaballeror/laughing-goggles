#!/bin/bash

pathsroot="/media/oscar"
paths="wbackups Data OS"
junks=( desktop.ini thumbs.db .nomedia 'System Volume Information')
mounted=""

lastpos=$(( ${#junks[*]} -1 ))
lastelem=${junks[$lastpos]}

for dir in $paths; do
	path="$(readlink -f $pathsroot/$dir)"

	#If the folder is not mounted, mount it and add it to the "mounted" list
	if [ -z "$(df --output=target | grep -E "^$path$")" ];then
		echo "Mounting $path"
		sudo mount "$path" 2>/dev/null || continue
		mounted+="$path "
	fi
	for name in "${junks[@]}"; do
		find "$path" -iname "$name" -print -exec rm -rf {} \; 2>/dev/null
	done
done

#Unmount everything we had to mount ourselves
for mountpoint in $mounted; do
	echo "Umounting $mountpoint"
	sudo umount $mountpoint 2>/dev/null	
done


unset pathsroot paths junks lastpos lastelem junk name dir mounted mountpoint
