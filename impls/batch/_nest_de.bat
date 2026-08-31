@echo off
setlocal ENABLEDELAYEDEXPANSION
set _G.LEVEL=5
set "_L[5].TokenPtr=HELLO-PTR"
set "_L[5].Count=7"
echo T0=_L[!_G.LEVEL!].TokenPtr
echo T1=!_L[!_G.LEVEL!].TokenPtr!
echo T2=!_G.LEVEL!  ->  !_G.LEVEL!
set "_tmp=_L[!_G.LEVEL!].TokenPtr"
echo T3 tmp field, now try cond
if defined _L[!_G.LEVEL!].TokenPtr (echo T4=defined) else (echo T4=NOT defined)
echo --- two-step with call set ---
set "_f=_L[!_G.LEVEL!].TokenPtr"
call set "_v=%%!_f!%%"
echo T5 v=!_v!
set /a _L[!_G.LEVEL!].Count += 3
echo T6 Count=!_L[5].Count!
exit /b 0