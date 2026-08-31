@echo off
setlocal enabledelayedexpansion
rem t72: recursion isolation via setlocal/endlocal frames. _SUM persists via endlocal&set.
rem per step build+read one frame-local, sum (correctness: SUM must equal _D).
set _N=200
set _D=200
set /a _SUM=0
call :rec %_D%
echo SUM=%_SUM% EXPECT=%_D%
endlocal
exit /b 0

:rec
setlocal
set "v=1"
set /a _SUM=_SUM+v
set /a _g=%~1-1
if !_g! gtr 0 call :rec !_g!
endlocal & set "_SUM=%_SUM%"
exit /b 0