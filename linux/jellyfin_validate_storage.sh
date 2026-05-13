#! /usr/bin/env bash

######################################################
######################################################
# SCRIPT: jellyfin_validate_storage.sh
# PURPOSE: ensure dir structure and dir/file naming is what jellyfin looks for;
# AUTHOR: https://github.com/kalebpc
# VERSION: 1.0.0
# DATE: 2026.05.12
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

SCRIPT_NAME="jellyfin_validate_storage.sh"
SCRIPT_LOG="$HOME/Logs/jellyfin_validate_storage.log"

function help () {
	cat << EOF

Usage:
    $SCRIPT_NAME -S <string> [OPTION...]

Required Arguments:
    -s	<string>	path to directory

Options:
    -h,-help		show this help
    -n			perform dry run
    -x			debug

Example:
    $SCRIPT_NAME -S "$HOME/Videos/Movie Trailers"

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
	while getopts ":s:h :n :x" opt; do
		case $opt in
			s) SOURCE=$(awk '{$1=$1}1' <<<"$OPTARG")
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
	! [ -d "$SOURCE" ] || [ "$SOURCE" == "" ] && { add_log_entry "[         error] System could not find '$SOURCE'."; ((ERRORS++)); return 1; }
	return 0
}

function print_debug () {
	local datetime=$(date "+%Y-%m-%d %H-%M-%S")
	cat << EOF
[$datetime][source             ] $SOURCE
[$datetime][errors             ] $ERRORS
[$datetime][dryrun             ] $DRY_RUN
[$datetime][debug              ] $DEBUG
[$datetime][scriptlog          ] $SCRIPT_LOG
EOF
}

function validate_movies () {
	echo movies
	# TODO
}

function validate_shows () {
	echo shows
	# TODO
}

function run () {
	#/media/$USER/2 TB/Jellyfin/Movie Trailers/Sarah Foo (2005) [imdbid-0123456]
	if [[ "$SOURCE" =~ \/Movies\/? ]]; then
		validate_movies
	elif [[ "$SOURCE" =~ \/Shows\/? ]]; then
		validate_shows
	elif [[ "$SOURCE" =~ \/Movie\ Trailers\/? ]]; then
		validate_movies
	else
		add_log_entry "[         error] script supports validating Movies, Shows, and Movie Trialers dirs"; ((ERRORS++)); return 1
	fi
}

function main () {
	local DRY_RUN=false DEBUG=false SOURCE="" ERRORS=0
	
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

	echo "[        errors] '$ERRORS' errors occurred while running."
	[ "$DEBUG" == true ] && print_debug
}
main "$@"

