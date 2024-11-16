@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined MAL_BATCH_IMPL_SINGLE_FILE (
	call UTILITIES :UTILITIES_Init %~n0
) else (
	call :UTILITIES_Init %~n0
)

%|% MAIN Main
%-|%

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (

			set | find /C /V ""
			
			set "%%.Prompt=user> " & %|% IO WriteVar %%.Prompt
			%|% IO ReadEscapedLine
			if defined _G_RET (
				%|->% %%.Input
			) else (
				goto :Main
			)
			%|% MAIN REP %%.Input
		)
	)
%-|%

:MAIN_Read Mal -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Eval Mal -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Print Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%|% IO WriteEscapedLineVar %%.Mal
		%<-% _
	)
%-|%

:MAIN_REP Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%|% MAIN Read %%.Mal %->% %%.Mal
		%|% MAIN Eval %%.Mal %->% %%.Mal
		%|% MAIN Print %%.Mal
		%<-% _
	)
%-|%