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
		set "%%.T=%~1"
		call set "%%.Type=%%!%%.T!.Type%%"
		echo T1=!%%.Type!
		call set "%%.Type2=%%!%%.N!.Type%%"
		echo T2=!%%.Type2!
		set "_G.X=!%%.N!"
		call set "%%.Type3=%%_G.X.Type%%"
		echo T3=!%%.Type3!
	)
%-|%