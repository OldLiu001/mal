@echo off
setlocal ENABLEDELAYEDEXPANSION
set "_L[1]."
set /a _G.LEVEL=1
for %%. in (_L[!_G.LEVEL!].) do (
	set "%%.Input=(+ 1 2)"
	call :F %%.Input
)
exit /b 0
:F
echo  arg1=[%~1] arg1q=[%~1]
exit /b 0