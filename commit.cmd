@echo off

set cdate=%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%
set /p var=Commit Message:
git add .
git commit -m "%cdate% %var%"
git push
 
:end