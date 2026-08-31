@echo off
set _G.FAST=0
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)

%{% MAIN Main %}%
%-|%

:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.NS %}
		%{s% %%.NS Type Reader %}
		call NSUTIL :NSUTIL_Get "!%%.NS!" Type "%%.T"
		echo T=[!%%.T!]
	)
%-|%
