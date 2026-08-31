@echo off
setlocal enabledelayedexpansion
set _N=100
for /l %%i in (1,1,%_N%) do (
    set "x=1"
    set "y=2"
    set "z=3"
)
endlocal
exit /b 0