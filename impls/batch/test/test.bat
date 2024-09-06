@echo off
@echo off & pushd "%~dp0" & setlocal ENABLEDELAYEDEXPANSION
for %%. in (1) do (
	echo 1
	goto 3
	:2
	echo 2
	:3
	echo 3
)
pause