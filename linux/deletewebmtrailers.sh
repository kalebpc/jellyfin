#! /usr/bin/env bash

######################################################
######################################################
# SCRIPT: 
# PURPOSE: delete webm trailers; move mp4 trailer from extras to main; delete extras folder
# AUTHOR: https://github.com/kalebpc
# VERSION: 1.0.0
# DATE: 2026.05.06
######################################################
######################################################
# Copyright (c) 2026 https://github.com/kalebpc
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
######################################################
######################################################

# take path input from arg
function help () {
	cat << EOF

Usage:
    $SCRIPT_NAME [OPTION...]

Required Arguments:
    -p                  path to 'trailers' folder

Options:
    -h,-help		show this help
    -n			perform dry run
    -x                  print debug

Example:
    $SCRIPT_NAME -p $PATH

EOF
}
DRY_RUN=false
DEBUG=false
FOLDER=""
while getopts ":p:n :x :h" opt; do
	case $opt in
		p) FOLDER="$OPTARG"
		;;
		n) DRY_RUN=true
		;;
		x) DEBUG=true
		;;
		h) { help; exit 0; }
		;;
		\?) { echo "Invalid option argument -$OPTARG" >&2; help; exit 1; }
		;;
	esac
	case "$OPTARG" in
		-*) { echo "Invalid option argument -$opt='$OPTARG'" >&2; help; exit 1; }
		;;
	esac
done

! [ -d "$FOLDER" ] && { echo "No path given. -p='$FOLDER'"; help; exit 1; }

function print_debug () {
	local datetime=$(date "+%Y-%m-%d %H-%M-%S")
	cat << EOF
[$datetime][work folders       ] $WRKFOLDERS
[$datetime][deleted count      ] $DELETED
[$datetime][renamed count      ] $RENAMED
[$datetime][created count      ] $CREATED
[$datetime][error count        ] $ERRORS
[$datetime][total folders      ] $TOTALFOLDERS
[$datetime][path               ] $FOLDER
[$datetime][dryrun             ] $DRY_RUN
[$datetime][debug              ] $DEBUG
EOF
}

#[ "$DEBUG" == "true" ] && print_debug
DELETED=0
function delete_webm () {
	webcount=0
	mpcount=0
	webfil=""
	local mpfil
	for x in "$1"/*; do
		[[ "$x" =~ .*\.webm$ ]] && { ((webcount++)); webfil="$x"; }
		[[ "$x" =~ .*\.mp4$ ]] && ((mpcount++))
	done
	if [ $webcount -eq 1 ] && [ $mpcount -eq 1 ]; then
		((DELETED++))
		[ "$DRY_RUN" == "false" ] && rm "$webfil" || echo "rm $webfil"
	fi
}

RENAMED=0
function rename_lone_mp4 () {
	trailercount=0
	nontrailercount=0
	for x in "$1"/*; do
		[[ "$x" =~ .*\ \-\ trailer. ]] && ((trailercount++)) || ((nontrailercount++))
	done
	if ! [ "$trailercount" -gt 0 ]; then
		for x in "$1"/*; do
			if ! [[ "$x" =~ .*\ \-\ trailer. ]]; then
				if [ "$DRY_RUN" == "false" ]; then
					mv "$x" "${x%]*}] - trailer.${x##/*.}"
				else
					#echo "mv \"$x\"" ; echo "   \"${x%]*}] - trailer.${x##/*.}\""
					echo "mv \"$x\" \"${x%]*}] - trailer.${x##/*.}\""
				fi
			fi
		done
		((RENAMED++))
	fi
}

CREATED=0
function create_movie_filler () {
	for x in "$1"/*; do
		newfiller="${x%]*}].${x##/*\.}"
		if ! [ -f "$newfiller" ]; then
			if [ "$DRY_RUN" == "false" ]; then
				ffmpeg -f lavfi -i "color=c=black:s=720x480:d=1" "$newfiller" && ((CREATED++))
			else
				echo "[dryrun ] ffmpeg -f lavfi -i \"color=c=black:s=720x480:d=1\" \"$newfiller\"" && ((CREATED++))
			fi
		fi
	done
}

TOTALFOLDERS=0
WRKFOLDERS=0
ERRORS=0
for fold in "$FOLDER"/*; do
	((TOTALFOLDERS++))
	for fil in "$fold"/*; do
		# verify existence of mp4 file in extras folder
		if [ -d "$fil" ] && [[ "$fil" =~ extras ]]; then
			((WRKFOLDERS++))
			for x in "$fil"/*; do
				# move mp4 out of extras
				[ "$DRY_RUN" == "false" ] && mv "$x" "${x/]*/]}/" || echo "mv $x ${x/]*/]}/"
				# delete extras folder
				[ "$DRY_RUN" == "false" ] && { rmdir "${x%/*}" && : || (($ERRORS++)); } || echo "rmdir ${x%/*}"
			done
		fi
	done
	delete_webm "$fold"
	rename_lone_mp4 "$fold"
	create_movie_filler "$fold"
done


[ "$DEBUG" == "true" ] && print_debug

# if mp4 and webm exist in folder delete webm file

