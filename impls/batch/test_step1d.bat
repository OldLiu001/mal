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
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)

%{% MAIN Main %}%
%-|%

:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% TYPES NewMal MalNum "42" %}% %->% %%.Mal
		echo Mal=[!%%.Mal!]
		%{g% "!%%.Mal!" Type %%.T %}
		echo Type=[!%%.T!]
		%{g% "!%%.Mal!" Value %%.V %}
		echo Value=[!%%.V!]
		%{% STR FromVar %%.V %}% %->% %%.StrMal
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		echo Result=[!%%.Result!]
	)
%-|%
