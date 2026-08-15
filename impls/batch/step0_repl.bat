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
		set "%%.Prompt=user> "
	)
	:MAIN_REPL_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% IO WriteVar %%.Prompt %}%
		%{% IO ReadEncLine %}% %->% %%.Input
		if defined %%.Input (
			%{% MAIN REP %%.Input %}%
		) else (
			exit /b 0
		)
	)
	goto MAIN_REPL_Loop
%-|%

:MAIN_Read Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Eval Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Print Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%{% IO WriteEncLine %%.Mal %}%
		%<-% %%.Mal
	)
%-|%

:MAIN_REP Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%{% MAIN Read %%.Mal %}% %->% %%.Mal
		%{% MAIN Eval %%.Mal %}% %->% %%.Mal
		%{% MAIN Print %%.Mal %}% %->% %%.Mal
	)
%-|%