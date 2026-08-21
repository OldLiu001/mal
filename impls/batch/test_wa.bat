@echo off
setlocal ENABLEDELAYEDEXPANSION
set "R=(+ 1 2)"
echo W0
echo."!R!"| call WRITEALL
echo W1
exit /b 0