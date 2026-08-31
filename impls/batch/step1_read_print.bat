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
		%{% MAIN REP %%.Input %}%
		%?% (
			if "!_G.ERR.Type!" == "Exception" (
				%{% IO WriteErrLineVar _G.ERR.Msg %}%
			) else if "!_G.ERR.Type!" == "Empty" (
				rem do nothing.
			) else (
				%?|% "Error type '!_G.ERR.Type!' not support."
			)

			for /f "delims==" %%a in (
				'set _G.ERR 2^>nul'
			) do set "%%a="
		)
	)
	goto MAIN_REPL_Loop
%-|%

:MAIN_Read Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% READER ReadString "!%%.Str!" %}% %->% %%.Mal
		%?% %-|%
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
		%{% PRINTER PrintMalType "%%.Mal" %}% %->% %%.StrMal
		%?% (
			%-|%
		)
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		%?% (
			%-|%
		)
		%{% IO WriteEncLine %%.Result %}%
		%<-% %%.Result
	)
%-|%

:MAIN_REP Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% MAIN Read "%%.Str" %}% %->% %%.Mal
		%?% (
			%-|%
		)
		%{% MAIN Eval %%.Mal %}% %->% %%.Mal2
		%?% (
			%-|%
		)
		%{% MAIN Print %%.Mal2 %}%
	)
%-|%
