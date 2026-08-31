@echo off
setlocal ENABLEDELAYEDEXPANSION
set _G.LEVEL=5
set "_L[5].TokenPtr=HELLO-PTR"
set "_L[5].Sym=SYMBOL-VAL"
set "_L[5].Str=  abc  "

echo === A: two-pass via percent prefix var ===
set "_T.P=_L[!_G.LEVEL!]."
echo A1=!_L[5].TokenPtr!            (plain control: value)
echo A2=!%_T.P%TokenPtr!            (both passes target var built in percent pass)
echo A3=!%_T.P%Sym!
echo A4=["!%_T.P%Str!"]

echo === B: nested if-defined context ===
if defined _L[!_G.LEVEL!].Sym (echo B1=defined) else (echo B1=no)

echo === C: set /a arithmetic target ===
set /a "_L[!_G.LEVEL!].Cnt=10"
set /a "_L[!_G.LEVEL!].Cnt += 5"
echo C1 Cnt=!_L[5].Cnt!

echo === D: call set double expansion ===
call set "_v=%%_L[!_G.LEVEL!].Sym%%"
echo D1 callset=!_v!

echo === E: percent-prefix with numeric suffix in condition ===
if "!%_T.P%TokenPtr!" == "HELLO-PTR" (echo E1=cond-match) else (echo E1=cond-no)

exit /b 0