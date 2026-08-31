@echo off
setlocal enabledelayedexpansion
rem t70: BASELINE - pure call-recursion, NO frame-local, NO isolation mechanism.
rem establishes the floor cost of `call :rec N` recursion alone at depth _D.
set _N=200
set _D=200
set /a _SUM=0
call :rec %_D%
echo SUM=%_SUM% EXPECT=%_D%
endlocal
exit /b 0

:rec
set /a _SUM+=1
set /a _g=%~1-1
if !_g! gtr 0 call :rec !_g!
exit /b 0