#!/bin/bash

devFile=$HOME/.global/devices

if [ $# -lt 1 ]; then
	echo Err: No arguments received\!
	exit 1
fi

if ! [ $1="off" ] && ! [ $1="on" ] && ! [ $1="state" ]; then
	echo "Err: Dind't get a suitable argument. [on|off|state]"
	exit 1
fi

if ! hash iwconfig > /dev/null 2> /dev/null; then
	while true; do
		echo "Err: iwconfig is not installed. Do you want me to try and get the wireless_tools package [Y/n]?: "
		read opt
		if [ $opt ] && [ $opt='y' ]; then
			if hash pacman > /dev/null 2> /dev/null; then
				sudo pacman -S wireless_tools
			elif hash apt > /dev/null 2> /dev/null; then
				sudo apt-get install wireless_tools
			elif hash zypper > /dev/null 2> /dev/null; then
				sudo zypper install wireless_tools
			#potentially add more here
			fi
			break
		elif [ $opt='n' ]; then
			echo "Please install it yourself if you want to use this script"
			exit 3
		fi
	done
fi

device=$(iwconfig 2> /dev/null | head -1 | cut -d ' ' -f1)
if [ $device ]; then
	#echo Using device $device
	if ! [ -d $HOME/.global ]; then
		mkdir -p $HOME/.global
	fi
	if ! [ -f $devFile ]; then
		#echo "Adding wlan to devices file"
		echo wlan $device > $devFile
	elif [[ $(grep wlan $devFile | cut -f2 -d ':' | cut -b 2-) != $device ]]; then 
		#echo "Modifying devices file"
		grep -v wlan $devFile > .tmp_devices
		echo wlan: $device >> .tmp_devices
		mv .tmp_devices $devFile
	#else
		#echo "Dev file already has this info. Moving on..."
	fi
else
	#echo "No wireless device found. Checking the devices file"
	if ! [ -f $devFile ]; then
		echo "Err: No wireless device has been found and no devices file exists"
		exit 2
	fi
	device=$(grep wlan $devFile | cut -f2 -d ':' | cut -b 2-)
	#echo "Found device $device in devices file"
	if ! [ $device ] || [ ! $(iwconfig 2> /dev/null | grep $device) ]; then
		echo "Err: No wireless device has been found and devices file contains no useful information"
		exit 2
	#else
		#echo "Found device " $device ". Continuing"
	fi
fi

if [ $1 = "state" ]; then
	state=$(ip link show $device | grep "state .* mode" | cut -d ' ' -f2)
	echo "$device is $state"
else
	sudo iwconfig $device txpower $1
fi