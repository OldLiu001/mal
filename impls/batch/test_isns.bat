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
		%{n% %%.N %}
		echo N=!%%.N!
		REM IsValidNS with NS ref value
		%{% NSUTIL IsValidNS "!%%.N!" %}% %->% %%.R1
		echo R1=!%%.R1!
		REM IsValidNS with var name
		%{% NSUTIL IsValidNS "%%.N" %}% %->% %%.R2
		echo R2=!%%.R2!
		REM direct type read
		call set "_T=%%!%%.N!.Type%%"
		echo T=!_T!
		REM Get Type with ref value
		%{g% "!%%.N!" Type %%.G1 %}
		echo G1=!%%.G1!
		REM Set then Get
		%{s% %%.N Type MyType %}
		%{g% "!%%.N!" Type %%.G2 %}
		echo G2=!%%.G2!
		REM Get with var name
		%{g% "%%.N" Type %%.G3 %}
		echo G3=!%%.G3!
	)
%-|%