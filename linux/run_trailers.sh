#! /usr/bin/env bash

######################################################
######################################################
# SCRIPT: run_trailers.sh
# PURPOSE: run script with args to run sync_remove_dup_trailers.sh
# AUTHOR: https://github.com/kalebpc
# VERSION: 1.0.0
# DATE: 2026.05.11
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

./sync_remove_dup_trailers.sh -S "/media/$USER/2 TB/Jellyfin/Movie Trailers" -D "/media/$USER/2 TB/Jellyfin/Movies" -P "/media/$USER/2 TB/Temp-PostProcessed"

