#!/bin/bash

devFile=$HOME/.global/devices

if [ $# -lt 1 ]; then
	echo "No argument provided"
	exit 1
fi

###########################################################
# First make sure we have our beloved devices file
###########################################################
if ! [ -d $HOME/.global ]; then
	mkdir -p $HOME/.global
fi
if ! [ -f $devFile ]; then
	touch $devFile
fi

###########################################################
#A function to check if a device number is present
###########################################################
present(){
	#Regular expression to check if it's a number. If it's not, we may
	#assume the supposed device number is incorrect and we got ourselves
	#a string... or nothing
	re='^[0-9]+$'
	if ! [[ $1 =~ $re ]] ; then
   		echo "Device not present"
   		return 0
   	else
   		return 1
	fi
}


###########################################################
# Find our device
###########################################################
devName=$(grep touchpad $devFile | cut -f2 -d ':' | cut -b 2-)
if ! [[ $devName ]]; then
	device=$(xinput list | grep -i touchpad | cut -f 2 | cut -b 4,5)
	if ! [[ $device ]]; then
		echo "Err: No wireless devices has been found and devices file contains no information relative to touchpad"
		exit 2
	else
		present $device
		if [ $? != 1 ]; then
			echo "Err: Found device " $device ". But it's not present"
			exit 2
		#else 
			#echo "1Found device " $device ". Continuing"
		fi
	fi
else
	#echo "Found device named" $devName ". Continuing"
	# Translate device name into it's number
	device=$(xinput list | grep -i "$devName" | cut -f 2 | cut -b 4,5)
	present $device
	if [ $? != 1 ]; then
		echo "Err: Found device " $device ". But it's not present"
		exit 2
	fi
fi

#echo Using device \#$device

###########################################################
# Now let's do something with our device
###########################################################

case $1 in
	"on"|"ON"|1)
		xinput set-prop $device "Device Enabled" 1;;
	"off"|"OFF"|0)
		xinput set-prop $device "Device Enabled" 0;;
	# A custom version of xinput is needed. Just get the source code and remove
	# the "while(1)" loop in the watch_props function, located in property.c
	"toggle")
		status=$(xinput watch-props $device | grep "Device Enabled" | cut -f 3)
		if [ $status -eq "1" ]; then
			xinput set-prop $device "Device Enabled" 0
		elif [ $status -eq "0" ]; then
			xinput set-prop $device "Device Enabled" 1
		else
			echo "Error. Device Enabled query returned" $status
			exit 2
		fi;;
	*)
		echo "What the hell is" $1
		exit 1;;
esac


###########################################################
# And in case it wasn't already, add it to the devices file
###########################################################

if ! [[ $devName ]]; then
	devName=$(xinput list | cut -f 5- -d ' ' | grep "id=$device" | cut  -f1)
fi
if [[ $(grep touchpad $devFile | cut -f2 -d ':' | cut -b 2-) != $devName ]]; then 
	echo "Modifying devices file"
	grep -v touchpad $devFile > .tmp_devices
	echo "touchpad: $devName" >> .tmp_devices
	mv .tmp_devices $devFile
#else
	#echo "Dev file already has this info. Moving on..."
fi
