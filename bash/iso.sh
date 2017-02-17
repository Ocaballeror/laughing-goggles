#!/bin/bash


if [ $# -lt 1 ]; then
	echo "No arguments provided"
	exit 1
fi

FILE=$1
filename="${FILE%%.*}"
extension="${FILE##*.}"
out=$filename.iso

if [ $# -gt 1 ]; then
	out=$2
fi

case $extension in 
	"mdf")
		if ! hash mdf2iso 2> /dev/null; then
			echo "Can\'t continue. mdf2iso is not installed"
		else
			mdf2iso $FILE $out
		fi;;
	"ccd"|"img")
		if ! hash ccd2iso 2> /dev/null; then
			echo "Can\'t continue. ccd2iso is not installed"
		else
			ccd2iso $FILE $out
		fi;;
	"nrg")
		if ! hash nrg2iso 2> /dev/null; then
			echo "Can\'t continue. nrg2iso is not installed"
		else
			nrg2iso $FILE $out
		fi;;
	"bin")
		if [ $# -lt 2 ]; then
			echo "2 files are needed"
			exit 1
		fi
		if ! hash bchunk 2> /dev/null; then
			echo "Can\'t continue. bchunk is not installed"
			exit 2
		fi

		FILE2=$2
		filename2="${FILE2%%.*}"
		extension2="${FILE2##*.}"

		if [ $extension2 != "cue" ]; then
			echo "Wrong format" $extension2
			exit 1
		fi

		if [ $# -gt 2 ]; then
			out=$3
		else
			out=$filename.iso
		fi

		bchunk $FILE $FILE2 $out;;

	"cue")
		if [ $# -lt 2 ]; then
			echo "2 files are needed"
			exit 1
		fi

		if ! hash bchunk 2> /dev/null; then
			echo "Can\'t continue. bchunk is not installed"
			exit 2
		fi

		FILE2=$2
		filename2="${FILE2%%.*}"
		extension2="${FILE2##*.}"

		if [ $extension2 != "bin" ]; then
			echo "Wrong format" $extension2
			exit 1
		fi

		if [ $# -gt 2 ]; then
			out=$3
		else
			out=$filename2.iso
		fi

		bchunk $FILE2 $FILE $out;;
	*)
		echo "I don't know what the fuck to do with" $1
esac
