#! /usr/bin/env bash

######################################################
######################################################
# SCRIPT: sync_jellyfin_media
# PURPOSE: Sync local jellyfin media directory with jellfin server media directory.
# AUTHOR: https://github.com/kalebpc
# VERSION: 1.0.0
# DATE: 2026.01.21
######################################################
######################################################
# Copyright (c) 2026 https://github.com/kalebpc

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
######################################################
######################################################

logdirpath="$HOME/Logs"
logfile="$logdirpath/rsync_jellyfin.log"

# NOTE: added / at end of localpath to copy contents
localpath="$HOME/Jellyfin/"
serverpath="$HOME/Jellyfin"

# ssh host
ssh="debian"

# Setting up log file.
# Check if logdirpath exists; create if not
! [ -d "$logdirpath" ] && { mkdir "$logdirpath" || printf "Could not create '%s'.\n" $logdirpath; exit 1; }
# Check if logfile exists; create if not
! [ -f "$logfile" ] && { touch "$logfile" || printf "Could not create '%s'.\n" $logfile; exit 1; }

# Check if localpath exists.
! [ -d "$localpath" ] && { printf "Could not locate localpath: '%s'.\n" $localpath; exit 1; }

# Sync localpath with serverpath
rsync -ruPavh $localpath $ssh:$serverpath --log-file=$logfile && rsync -ruPavh $ssh:$serverpath/ $localpath --log-file=$logfile

# Check rsync exit code
[[ $? -eq 0 ]] && printf "\nSuccess\n"; exit 0 || printf "\nFailed\nexit %d\n" $?

