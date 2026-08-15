@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	call %2 %3 %4 %5 %6 %7 %8 %9 || %?|% "Call '%~nx0' failed."
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
			%?% (
				if "!_G.ERR.Type!" == "Exception" (
					%{% IO WriteErrLineVar _G.ERR.Msg %}%
				) else if "!_G.ERR.Type!" == "Empty" (
					rem do nothing.
				) else (
					%?|% "Error type '!_G.ERR.Type!' not support."
				)

				( set _G.ERR ) > "%TEMP%\mal_e.txt" 2>nul
				for /f "usebackq delims==" %%a in ("%TEMP%\mal_e.txt") do set "%%a="
			)
		) else (
			exit /b 0
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
