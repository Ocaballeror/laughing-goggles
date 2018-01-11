#!/bin/bash
#
# titanium_update.sh
# This script is used to synchronize the titanium backups on my phone with my computer.
# I store the current, most recent backups in a folder called 'Current' and old backups
# of apps I deleted in another one called 'Deleted'. This script pulls all the backups from
# the phone through ADB, then compares every file to the ones stored locally.
# 
# The pulled backups that correspond to new apps or newer versions of existing ones are kept,
# while the ones that have been superseeded are deleted. The local backups that don't have a
# new one to superseed them are assumed to be deleted apps, and are thus sent to the deleted 
# folder.

_exit() {
	if [ -d "$tmp" ]; then
		mv "$tmp"/* "$bkpath/Current"
		rmdir "$tmp"
	fi

	exit 127
}

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
