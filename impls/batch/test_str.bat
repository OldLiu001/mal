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
		%{% STR New %}% %->% %%.S
		%{% STR AppendVal %%.S "(" %}
		%{% STR AppendVal %%.S ")" %}
		%{% STR GetStr %%.S %}% %->% %%.R
	)
%-|%