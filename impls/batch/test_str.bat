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
call NSUTIL :NSUTIL_Init %~n0
%{% MAIN Main %}%
%-|%
:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		echo M1
		%{% STR New %}% %->% %%.S
		echo M2 S=!%%.S!
		%{% STR AppendVal %%.S "(" %}
		echo M3
		%{% STR AppendVal %%.S ")" %}
		echo M4
		%{% STR GetStr %%.S %}% %->% %%.R
		echo M5 R=!%%.R!
	)
%-|%