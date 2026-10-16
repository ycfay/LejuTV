#!/bin/bash
version_day=$(date +'%Y%m%d%H%M')
cd /Users/richie/Projects/LejuTV
git add .
git commit -m $version_day
git push

osascript -e 'tell application "Terminal" to close first window' & exit

