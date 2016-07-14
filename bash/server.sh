#!/bin/bash


#################################################################################
# A script to start or kill simple http servers using python's SimpleHTTPServer
#
#
# Licensed under WTFYW Public License, of course
#
# (c) Oscar Caballero 2016
#
#################################################################################



# Some constants
DEFPORT=8000
DEFBROWSER="chromium"
if ! hash $DEFBROWSER 2> /dev/null; then
	DEFBROWSER="chrome"
	if ! hash $DEFBROWSER 2> /dev/null; then
		DEFBROWSER="firefox"
	fi
fi

DEFCOMMAND="python -m SimpleHTTPServer"

# Check for python version and modify the command if necessary.
# Thank God, shell can make case distinction for its "constants"
if [ $(python --version | grep -Eo [0-9] | head -1) -gt 2 ]; then
	DEFCOMMAND="python2.7 -m SimpleHTTPServer"
fi


# Default options
port=$DEFPORT
browser=$DEFBROWSER
silent=0 # (-s)
nothing=0 # (-n)
moved=0 # (-d)
precise=0 # (-j)
newPort=0 # (-p)

#And some global variables, because why not
recursive=0 #Check if start is being called recursively

# Receives the command to be used to start the server
start(){

	if [ "$(ps aux | grep "$1" | grep -v grep)" ]; then
		if [ $silent = 0 ] && [ $recursive = 0 ]; then
			echo "A server is already started in port $port"
		fi

		[ $precise = 1 ] && return 0

		# Change the port in our command to the next one, 
		# then recursively call start to check again
		port=$(($port + 1))
		command="$DEFCOMMAND $port"
		recursive=1 #Indicate we are calling recursively to avoid too much output
		start "$command"
		return
	fi

	recursive=0

	if [ $silent = 0 ]; then
		echo "Starting server on 0.0.0.0:$port"
	fi
	
	# Command should now have the specified port
	$command > /dev/null 2> /dev/null &
	
	if [ $nothing = 0 ]; then
		$browser 0.0.0.0:$port > /dev/null 2> /dev/null &
	fi
}

# Receives the command used to start a server as a parameter
stop(){

	if [ $newPort = 0 ]; then
		#This should get the last server added to the ps aux list
		process=$(echo "$(ps aux | grep -v grep | grep -E "$DEFCOMMAND {0,1}[0-9]*")"| tail -1)
		#if ! [ "$process" ] && [ $newPort = 0 ]; then
		if [ -z "$process" ]; then
			>&2 echo "Err: There are currently no servers running"
			return 2			
		fi
	else
		process="$(ps aux | grep "$1" | grep -v grep)"
		if ! [ "$process" ]; then
			if [ $silent = 0 ] && [ $newPort = 1 ]; then
				>&2 echo "Err: There's not a server running on this port."
			fi	
			return 1
		fi
	fi

	if [ $silent = 0 ]; then
		#echo Killing process \#$(echo "$process" | grep -Eo "[0-9]{1,}" | head -1)
		
		#Get the last word of our process, which should theoretically be the port number
		killingPort=${process##* }
		if ! [[ $killingPort =~ ^[0-9]+$ ]]; then
			killingPort=$DEFPORT
		fi
		echo "Stopping server on port $killingPort"
	fi

	# Get the first number from ps aux, which should be the pid of our
	# process. The grep -v grep part eliminates the entry created by grep
	# itself from the process list.
	kill $(echo "$process" | grep -Eo "[0-9]+" | head -1) > /dev/null
	return 0
}

#You guessed it. It receives the command used to restart a server as a parameter
restart(){
	# Store current silent value for later
	oldSilent=$silent
	# Avoid stopping messages. Ain't nobody got time for that
	silent=1
	stop "$1"
	if [ $? != 0 ] && [ $oldSilent == 0 ]; then
		echo "No server was running on port $port. But I'll start it anyway"
	fi
	silent=$oldSilent
	start "$command"
}

list(){
	local i=0
	echo "$(ps aux | grep -v grep | grep -Eo "$DEFCOMMAND {0,1}[0-9]*")"\
	| while read server; do
		if ! [ "$server" ]; then
			echo "There are currently no active servers"
		else
			[ $i = 0 ] && echo "Currently active servers: "
			i=$(($i+1))
			port=${server##* }

			#Regular expression to check if it's a number. If it's not, we may
			#assume the command didn't have a port number at the end. Probably
			#because it was executed with an external command
			if ! [[ $port =~ ^[0-9]+$ ]] ; then
		   		port=$DEFPORT
		   	fi
			echo "  $i. Port $port"
		fi
	done
}

browse(){
	if [ $newPort = 0 ] && [ $(list | wc -l) -gt 1 ]; then
		2>& echo "Err: There's more than one server running and no port was specified(-p)"
		exit 2
	fi
	$browser 0.0.0.0:$port > /dev/null 2> /dev/null &
}

usage(){
	local this=$(basename "$0")

	echo "Usage: $this ACTION [OPTIONS]
OPTIONS:
	-p <port>:	Start server on a different port (Default $DEFPORT)
	-b <browser>:	Open a different browser (Default $DEFBROWSER)
	-d <path>:	Start server on the specified folder
	-j:	Don't use a new port if the specified one isn't available
	-n:	Don't launch a browser after starting the server (Overrides -b)
	-s:	Don't print anything
	-h:	Show this help message

ACTIONS:
	start:		Starts a server in the specified port (-p) or the first available one starting from $DEFPORT
	stop/kill:	Stops the server in the specified port (-p) or the most recently started one
	restart:	Stops and restarts a new server in the specified port
	open:		Open a browser int the server with the specified port
	list:		Lists all currently active servers
	killall:	Stops all currently active servers"
}


parse(){
	while getopts ":p:b:d:jnsh" opt; do
	 	case $opt in
		p)
			port=$OPTARG
			if [ $port -le 1023 ]; then
				>&2 echo "Err: Port number must be greater than 1023"
				exit 3
			fi
			newPort=1;;
		b)
			browser=$OPTARG
			if ! hash $browser 2> /dev/null; then
			  	>&2 echo "Err: Can't launch browser $browser"
		  		exit 3
			fi;;
		d)
			if ! [ -d $OPTARG ]; then
				>&2 echo "Err: Can't access specified folder $OPTARG"
		  		exit 1
			else
				oldDir=$(pwd)
				moved=1
				cd $OPTARG
			fi;;
		j)
			precise=1;;
		s)
			silent=1;;
		n)
			nothing=1;;
		h)
			usage
			exit 0;;
		\?)
			>&2 echo "Err: Invalid option: -$OPTARG"
			usage
			exit 1;;
		:)
			>&2 echo "Err: Option -$OPTARG requires an argument."
			exit 1;;
		esac
	done
}

###################### START PARSING & STUFF ####################

if [ $# = 0 ]; then
	usage
	#start "$DEFCOMMAND $DEFPORT"
	exit 1
fi


case $1 in
	"stop"|"kill")
		action="stop";;

	"start")
		action="start";;

	"restart")
		action="restart";;

	"open")
		action="browse";;

	"list")
		# Iterate over all the lines of this command's output. We use the 
		# default command because it doesn't have a port number attached
		list
		exit 0;;

	"killall")
		stop 2> /dev/null
		while [ $? = 0 ]; do
			stop 2> /dev/null
		done
		exit 0;;

	*)
		usage
		exit 1;;
esac

# Call the argument parser while ignoring other actions
while [ $# -gt 0 ]; do
	parse $*
	shift 1
done


# Either we changed the port or not, update the command so it always has the number
# and parsing it is easier (dat english, though)
command="$DEFCOMMAND $port"


##########################################################################
################### DONE WITH THE PARSING, LET'S EXECUTE #################

eval "$action" "$command"


if [ $moved = 1 ] && [ -d $oldDir ]; then
#Could use 'cd -' but this is easier to track and manipulate (in case it's ever needed)
	cd $oldDir 
fi