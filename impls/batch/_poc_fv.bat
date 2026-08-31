@echo off
setlocal ENABLEDELAYEDEXPANSION
set "_L[1]."
set /a _G.LEVEL=1
echo ARG1=%~1
for %%. in (_L[!_G.LEVEL!].) do (
	set "%%.Str=%~1"
	echo INSIDE Str=[!%%.Str!]
	set "%%.Str2=!%~1!"
	echo INSIDE Str2=[!%%.Str2!]
)
exit /b 0