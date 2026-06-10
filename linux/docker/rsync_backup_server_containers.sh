#! /usr/bin/env bash

######################################################
######################################################
# SCRIPT: rsync_backup_server_containers.sh
# PURPOSE: sync containers with server
# AUTHOR: https://github.com/kalebpc
# VERSION: 1.0.0
# DATE: 2026.05.08
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

logdirpath="$HOME/Logs"
logfile="$logdirpath/rsync_server_containers.log"

localpath="/home/$USER/Documents/containers"
serverpath="/home/$USER/Documents/containers"
backuppath="/home/$USER/Documents/backup-deleted"

# ssh host
ssh="debian"

# Setting up log file.
# Check if logdirpath exists; create if not
! [ -d "$logdirpath" ] && { mkdir -p "$logdirpath" || { printf "Could not create '%s'.\n" $logdirpath; exit 1; }; }

# Check if logfile exists; create if not
! [ -f "$logfile" ] && { touch "$logfile" || { printf "Could not create '%s'.\n" $logfile; exit 1; }; }

# Check if localpath exists.
! [ -d "$localpath" ] && { mkdir -p "$localpath" || { printf "Could not create localpath: '%s'.\n" $localpath; exit 1; }; }

# NOTE: added / at end of source to copy contents
# Backup $serverpath to $localpath
# rsync -ruPavh $ssh:$serverpath/ $localpath --log-file=$logfile && rsync -ruPavh $localpath/ $ssh:$serverpath --log-file=$logfile

rsync -ruPavh --exclude='*lib/tailscale*' --exclude='*/logrotate*' --exclude='*/postgres*' --exclude='*tunarr-data/data.ms*' --exclude='*tunarr-data/db.db*' --delete --backup-dir=$backuppath/$(date "+%Y_%m_%d-(%H-00)") $ssh:$serverpath/ $localpath --log-file=$logfile

rsync -ruPavh --delete --backup-dir="/media/$USER/2 TB/backup-deleted/$(date "+%Y_%m_%d-(%H-00)")" $ssh:/mnt/sata_drive/Immich/ "/media/$USER/2 TB/Immich" --log-file=$logfile
