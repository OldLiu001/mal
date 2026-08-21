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
		%{n% %%.NS %}
		%{s% %%.NS Type Reader %}
		
		set "!%%.NS!.Target" 
		set "!%%.NS!.Target" 2>nul | echo TargetFromMeta=[!_G.NS[2].Target!]
		
		set "%%.NSBody=!_G.NS[2].Target!"
		echo NSBody=[!%%.NSBody!]
		echo Value=[!_G.NS[1].Data.Value[Type]!]
		set "%%.T=!_G.NS[1].Data.Value[Type]!"
		echo T_direct=[!%%.T!]
		
		call NSUTIL :NSUTIL_Get "!%%.NS!" Type "%%.T2"
		echo T2=[!%%.T2!]
	)
%-|%
