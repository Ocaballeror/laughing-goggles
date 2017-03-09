#!/bin/bash

# TODO Add passphrase prompt
# Connect to the given ssid
usage(){
	echo "Usage: ${FUNCNAME[0]} [options] <ssid>"
	echo "Available options: "
	echo "	-i: Specify the network interface to be used"
	echo "	-s: Scan for available networks"
	echo "	-k: Kill a running wpa_supplicant process"
	echo "	-l: List saved wpa configurations in $confdir"
	echo "	-h: Show this help message"
}

errcho(){
	echo $* >&2
}


##### FIND THE WIRELESS INTERFACE ##### 
# We need the wireless interface before everything else
interface="$(echo $* | grep -oP -- '-i \K[^ ]+')"
if [ -z "$interface" ]; then
	if hash iw 2>/dev/null; then
		interface="$(iw dev | grep -Po "Interface \K.*" | head -1)" 
	elif hash iwconfing 2>/dev/null; then
		interface="$(iwconfig 2>/dev/null | head -1 | cut -d ' ' -f1)"
	else
		errcho "Err: Could not find wireless interface. Please specify it with -i"
		exit 3
	fi
fi
#########################################

##### FIND THE NETWORK CARD DRIVER ##### 
driver="$(echo $* | grep -oP -- '-D \K[^ ]+')"
if [ -z "$driver" ]; then
	driver="$(lspci -k | grep -A3 Network | grep 'Kernel driver' | rev | cut -d ' ' -f1 | rev)"
fi
if [ -z "$driver" ]; then
	echo "W: Could not find the driver for the network card. Using wext as default"
	driver="wext"
fi
#########################################


##### PARSE CLI OPTIONS #####
while [ $# -gt 0 ] && [ ${1:0:1} = "-" ]; do
	if [ "$1" = "-l" ]; then
		ls $confdir
		exit 0
	elif [ "$1" = "-k" ]; then
		sudo pkill wpa_supplicant
		shift
	elif [ "$1" = "-s" ]; then
		# Show a pretty numbered list of the available networks
		local i=0
		$scancmd | grep -E ".SSID" |\
			while read line; do
				[ -n "$line" ] && echo "$line" | sed "s/E\?SSID: \?/$i. /g"
				i=$(($i+1))
			done
			exit 0
	elif [ "$1" = "-i" ]; then
		shift 2
	elif [ "$1" = "-h" ]; then
		_usage
		exit 0
	else
		echo "Err: Option "$1" not recognized"
		_usage
		exit 0
	fi
done
#########################################

##### FIND THE CONFIGURATION FILE #####
local confdir=/etc/wpa_supplicant
[ ! -d $confdir ] && echo "Err: $confdir does not exist"

local conffile="$1"
if [ ! -f "$confdir/$conffile" ];  then
	# Try very hard to find a similar filename
	conffile="$1.conf"
	[ ! -f "$confdir/$conffile" ] && conffile="$(ls $confdir | grep -i "^$1$" | head -1)"
	[ ! -f "$confdir/$conffile" ] && conffile="$(ls $confdir | grep -i "^$1.conf$" | head -1)"

	if [ ! -f "$confdir/$conffile" ]; then
		echo "Err: configuration for $1 not found in $confdir"
		exit 2
	fi
fi
#########################################

##### CONNECT TO THE NETWORK #####
if ! ip addr show $interface >/dev/null 2>&1; then
	echo "Err: Interface '$interface' not found"
	exit 2	
fi

sudo ip link set dev $interface down
[ $? = 0 ] || exit 3
sudo ip link set dev $interface up
[ $? = 0 ] || exit 3
sudo wpa_supplicant -D$driver -i$interface -c "$confdir/$conffile" >/dev/null &
#########################################
