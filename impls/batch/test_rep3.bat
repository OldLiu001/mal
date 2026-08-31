@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step1_read_print
:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Input=(+ 1 2)"
		echo R0
		for /l %%_ in () do (
			echo R0_5
			%{% MAIN REP %%.Input %}
			echo R1
			exit /b 0
		)
	)
%-|%