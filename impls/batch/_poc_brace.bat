@echo off
setlocal ENABLEDELAYEDEXPANSION
set "a=(+ 1 2)"
echo %% style:
set "X=%~1"
echo X=[%X%]
echo %% with arg in percent:
echo arg1pct=[%~1]
echo with bang:
set "Y=!a!"
echo Y=[!Y!]
exit /b 0