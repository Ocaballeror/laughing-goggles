#!/bin/bash
#
# titanium_update.sh
# Pull the latest titanium backups and update our local backup folder

# First check that we have available ADB devices
hash adb 2>/dev/null || { echo "Err: ADB is not installed"; exit 3; }
adb devices | grep -w device >/dev/null 2>&1 || { echo "Err: No adb device found"; exit 3; }

# Set some handy variables
bkpath="/media/oscar/Data/Software/Android/Backups/TitaniumBackup"
current="$bkpath/Current"
tmp="$(mktemp -d)"
names="$(mktemp)"

[ ! -d "$bkpath" ] && { echo "Err: Backup path is not available"; exit 2; }
[ ! -d "$current" ] && { echo "Err: Backup path is not available"; exit 2; }

# See what's in the backup folder already
mv "$current/*" $tmp
ls $tmp | cut -d- -f1 | uniq > $names

# Get the new backups
adb pull /sdcard/TitaniumBackup "$current" >/dev/null 2>&1

# For every new file, delete their corresponding old backup from the tmp folder
for file in "$current"; do
	base="$( echo "$file" | cut -d- -f1 )"
	if grep $base $names; then
		rm -f "$tmp/$base-*"
	fi
done

# The files remaining in the tmp folder have not been matched, so they must be backups for deleted apps 
mv $tmp/* $bkpath/Deleted

rm -rf "$tmp" "$names"
unset bkpath current tmp names file base
