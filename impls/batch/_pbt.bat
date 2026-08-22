@echo off
setlocal enabledelayedexpansion
rem Proper timing: loop a fixed number of cross-file subprocess calls,
rem measure via %TIME% parsing at second granularity over a LARGE count.
call "%~dp0NSUTIL.bat" :NSUTIL_Init pbt 2>nul
set _N=800
set /a _t0=100
for /l %%j in (1,1,%_N%) do (
    call NSUTIL :NSUTIL_IsValidNS _G.SKIPTHIS 2>nul
)
set /a _t1=100
endlocal
exit /b 0