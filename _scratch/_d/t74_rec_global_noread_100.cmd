@echo off
setlocal enabledelayedexpansion
rem t74: global-index, WRITE-ONLY frame local (no indirect read). data flows via call args.
rem best-case for the global-index idea: isolation via unique names, sum via arg return.
set _N=100
set _D=100
set /a _G.IDX=0
call :rec %_D% 0
echo SUM=%_s% EXPECT=%_D%
endlocal
exit /b 0

:rec
set /a _G.IDX+=1
set "_I%_G.IDX%.x=1"
set /a _g=%~1-1
set /a _s=%~2+1
if !_g! gtr 0 call :rec !_g! !_s!
set /a _G.IDX-=1
exit /b 0