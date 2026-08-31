@echo off
setlocal enabledelayedexpansion
rem t73: recursion isolation via SELF-MAINTAINED GLOBAL INDEX (no setlocal, no for-var).
rem per step build unique var name from global counter, write, indirect-read, sum.
set _N=50
set _D=50
set /a _G.IDX=0
set /a _SUM=0
call :rec %_D%
echo SUM=%_SUM% EXPECT=%_D%
endlocal
exit /b 0

:rec
set /a _G.IDX+=1
set "_nm=_I!_G.IDX!.v"
set "!_nm!=1"
call set "_t=%%!_nm!%%"
set /a _SUM+=!_t!
set /a _g=%~1-1
if !_g! gtr 0 call :rec !_g!
set /a _G.IDX-=1
exit /b 0