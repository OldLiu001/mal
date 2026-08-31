@echo off
setlocal enabledelayedexpansion
set _N=100
for /l %%i in (1,1,%_N%) do set "x=1"
endlocal
exit /b 0
:NOP
set "x=1"
exit /b 0