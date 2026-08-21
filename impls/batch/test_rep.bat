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
		%{% MAIN Read "%%.Input" %}% %->% %%.Mal
		%?% ( echo M1ERR: !_G.ERR.Msg! & exit /b 0 )
		%{% MAIN Eval %%.Mal %}% %->% %%.Mal2
		%?% ( echo M2ERR: !_G.ERR.Msg! & exit /b 0 )
		%{% MAIN Print %%.Mal2 %}
	)
%-|%