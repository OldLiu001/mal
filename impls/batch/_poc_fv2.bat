@echo off
setlocal ENABLEDELAYEDEXPANSION
set "_L[1]."
set /a _G.LEVEL=1
echo A: for-var with paren value
for %%. in (_L[!_G.LEVEL!].) do (
	set "%%.Str=(+ 1 2)"
	echo INNER=[!%%.Str!]
)
echo done-A
exit /b 0