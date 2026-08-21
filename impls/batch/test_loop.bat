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
		for /l %%_ in () do (
			echo A1
			%{% IO WriteVal "hi" %}%
			echo A2
			%{n% %%.N %}
			echo A3 N=!%%.N!
			%{% NSUTIL Free "!%%.N!" %}%
			echo A4
			exit /b 0
		)
	)
%-|%