#! /usr/bin/env bash

######################################################
######################################################
# SCRIPT: sync_remove_dup_trailers.sh
# PURPOSE: take in path to 'movie trailers' and 'movies'; match trailers with existing movies; move trailer file to corresponding movie folder; remove trailer folder from 'movie trailers'
# AUTHOR: https://github.com/kalebpc
# VERSION: 1.0.0
# DATE: 2026.05.09
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

SCRIPT_NAME="./sync_remove_dup_trailers.sh"
SCRIPT_LOG="${HOME}/Logs/sync_remove_dup_trailers.log"

function help () {
	cat << EOF

Usage:
    $SCRIPT_NAME -S <string> -D <string> -p <string> -s <string> -d <string> -t <string> [OPTION...]

Required Arguments:
    -S	<string>	path to movie trailers directory
    -D	<string>	path to movies directory

Options:
    -P	<string>	path to post-processed folder; folders will be moved here
    -h,-help		show this help
    -n			perform dry run
    -x			debug

Example:
    $SCRIPT_NAME -S "$HOME/Videos/Movie Trailers" -D "$HOME/Videos/Movies" -P "$HOME/temp trash"

EOF
}

function add_log_entry () {
	echo "[$(date "+%H:%M:%S")] $1" >&2
	if [ "$DRY_RUN" == "false" ]; then
		echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >> "$SCRIPT_LOG"
		[ $? -ne 0 ] && printf "[         error] Failed to add entry to '%s'.\n" "$1" >&2
	fi
}

function set_opts () {
	while getopts ":S:D:P:h :n :x" opt; do
		case $opt in
			S) SOURCE=$(awk '{$1=$1}1' <<<"$OPTARG")
			;;
			D) DEST=$(awk '{$1=$1}1' <<<"$OPTARG")
			;;
			P) PROCESSED=$(awk '{$1=$1}1' <<<"$OPTARG")
			;;
			h) help; exit 0
			;;
			n) DRY_RUN=true
			;;
			x) DEBUG=true
			;;
			\?) echo "Invalid option argument -$OPTARG" >&2; help; exit 1
			;;
		esac
		case "$OPTARG" in
			-*) echo "Invalid option argument -$opt='$OPTARG'" >&2; help; exit 1
			;;
		esac
	done
}

function verify_user_input () {
	! [ -d "$SOURCE" ] && { add_log_entry "[         error] System could not find '$SOURCE'."; ((ERRORS++)); return 1; }
	! [ -d "$DEST" ] && { add_log_entry "[         error] System could not find '$DEST'."; ((ERRORS++)); return 1; }
	if ! [ -d "$PROCESSED" ]; then
		if [ "$PROCESSED" == "" ]; then
			PROCESSED="$HOME/tmp"
			add_log_entry "[  creating dir] Creating processed folder: '$PROCESSED'."
		fi
		add_log_entry "[  creating dir] Creating processed folder: '$PROCESSED'."
		[ "$DRY_RUN" == "false" ] && { mkdir -p "$PROCESSED"; [ $? -ne 0 ] && { add_log_entry "[         error] System could not create processed folder: '$PROCESSED'."; ((ERRORS++)); return 1; }; }
	fi
	return 0
}

function print_debug () {
	local datetime=$(date "+%Y-%m-%d %H-%M-%S")
	cat << EOF
[$datetime][scriptlog          ] $SCRIPT_LOG
[$datetime][processed          ] $PROCESSED
[$datetime][source             ] $SOURCE
[$datetime][destination        ] $DEST
[$datetime][dryrun             ] $DRY_RUN
[$datetime][debug              ] $DEBUG
[$datetime][errors             ] $ERRORS
EOF
}

function deal_with_existing_trailers () {
	local destfold="$1"
	local fil
	for fil in "$destfold"/*; do
		if [[ "$fil" =~ .*\ \-\ trailer.* ]]; then 
			if ! [ -d "$destfold/extras" ]; then
				add_log_entry "[ create folder] '$destfold/extras'"
				[ "$DRY_RUN" == false ] && { mkdir "$destfold/extras"; [ $? -ne 0 ] && { add_log_entry "[         error] while trying to create '$destfold/extras'"; ((ERRORS++)); }; }
			fi
			if [ "$DRY_RUN" == false ]; then
				if ! [ -f "$destfold/extras/${fil##/*/}" ]; then
					add_log_entry "[moving trailer] '$fil' to '$destfold/extras/'"
					mv "$fil" "$destfold/extras/"
					[ $? -ne 0 ] && { add_log_entry "[         error] while trying to move '$fil' to '$destfold/extras/'."; ((ERRORS++)); }
				else
					local tmp="$(date "+%Y-%m-%d %H:%M:%S")-${fil##/*/}"
					add_log_entry "[rename trailer] '$fil' to '$tmp'"
					add_log_entry "[moving trailer] '$fil' to '$destfold/extras/$tmp'"
					mv "$fil" "$destfold/extras/$tmp"
					[ $? -ne 0 ] && { add_log_entry "[         error] while trying to move '$fil' to '$destfold/extras/$tmp'."; ((ERRORS++)); }
				fi
			else
				add_log_entry "[moving trailer] '$fil' to '$destfold/extras/'"
			fi
		fi
	done
}

function copy_trailer_to_movie_fold () {
	local s_fold="$1"
	local d_fold="$2"
	local fil
	for fil in "$s_fold"/*; do
		if [[ "$fil" =~ .*\ \-\ trailer.* ]]; then
			add_log_entry "[  copy trailer] '$fil' to '$d_fold/'"
			[ "$DRY_RUN" == false ] && { cp "$fil" "$d_fold/"; [ $? -ne 0 ] && add_log_entry "[         error] while trying to copy '$fil' to '$d_fold/'."; }
		fi
	done
	
}

function remove_trailer_folder_from_movie_trailers () {
	add_log_entry "[ moving folder] '$1' to '$PROCESSED/'"
	[ "$DRY_RUN" == false ] && { mv "$1" "$PROCESSED/"; [ $? -ne 0 ] && { add_log_entry "[         error] while trying to move '$1' to '$PROCESSED/'."; ((ERRORS++)); }; }
}

function run () {
	local source_fold
	local dest_fold
	for source_fold in "$SOURCE"/*; do
		for dest_fold in "$DEST"/*; do
			# match trailers with corresponding existing movies
			if [ "${dest_fold##/*/}" == "${source_fold##/*/}" ]; then
				
				add_log_entry "[    dest match] $dest_fold"

				deal_with_existing_trailers "$dest_fold"

				copy_trailer_to_movie_fold "$source_fold" "$dest_fold"

				remove_trailer_folder_from_movie_trailers "$source_fold"

				printf "\n"
			fi
		done
	done
}

function main () {
	local DRY_RUN=false
	local DEBUG=false
	local SOURCE=""
	local DEST=""
	local PROCESSED=""
	local ERRORS=0
	
	# Setup logs
	! [ -d "${SCRIPT_LOG%/*}" ] && { mkdir -p "${SCRIPT_LOG%/*}"; [ $? -ne 0 ] && { echo "[         error] creating script log dir: '${SCRIPT_LOG%/*}'." >&2; exit 1; };  }
	! [ -f "$SCRIPT_LOG" ] && { > "$SCRIPT_LOG"; [ $? -ne 0 ] && { echo "[         error] creating script log file: '$SCRIPT_LOG'." >&2; exit 1; }; }
	
	# Catch no args run
	[ $# -ne 0 ] && set_opts "$@" || { add_log_entry "[         error] '$SCRIPT_NAME' requires arguments."; help; exit 1; }
	
	if verify_user_input; then
		run		
	else
		echo "Print help: $SCRIPT_NAME -h"; exit 1
	fi
	echo "[          NOTE] processed source folders moved to '$PROCESSED'."
	echo "[        errors] '$ERRORS' errors occurred while running."
	[ "$DEBUG" == true ] && print_debug
}
main "$@"

