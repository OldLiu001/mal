@echo off
setlocal ENABLEDELAYEDEXPANSION
set "var=_G.NS[2]"
echo Test: var=!var!
if "%~1" neq "" (
	call %*
) else (
	echo no args
)
echo Done
