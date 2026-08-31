@echo off
setlocal enabledelayedexpansion
rem t71: recursion isolation via PROJECT-STYLE for-var (.for-var domain + global LEVEL).
rem per step build+read one frame-local, sum (correctness: SUM must equal _D).
set _N=100
set _D=100
set /a _G.LEVEL=0
set /a _SUM=0
call :rec %_D%
echo SUM=%_SUM% EXPECT=%_D%
endlocal
exit /b 0

:rec
set /a _G.LEVEL+=1
for %%. in (_L[!_G.LEVEL!].) do (
    set "%%.v=1"
    set /a _SUM+=!%%.v!
    set /a _g=%~1-1
    if !_g! gtr 0 call :rec !_g!
)
set /a _G.LEVEL-=1
exit /b 0