@echo off
setlocal ENABLEDELAYEDEXPANSION
set "_L[1]."
set /a _G.LEVEL=1
set "arg=(+ 1 2)"
echo B: pass arg var into call-label
call :SUB "!arg!"
echo back
exit /b 0
:SUB
for %%. in (_L[!_G.LEVEL!].) do (
	set "%%.Str=%~1"
	echo INNER=[!%%.Str!]
)
exit /b 0