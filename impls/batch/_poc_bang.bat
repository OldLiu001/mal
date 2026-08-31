@echo off
setlocal ENABLEDELAYEDEXPANSION
set "Form=(def! x 3)"
echo FormRaw=[!Form!]
echo repr via echo: !Form!
call :SR "!Form!"
exit /b 0
:SR
echo  arg=[%~1]
set "_T.X=%~1"
echo  T.X=[!_T.X!]
exit /b 0