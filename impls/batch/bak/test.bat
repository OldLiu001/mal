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
			set | find /C /V ""
set VSCODE_NLS_CONFIG
rem echo %VSCODE_NLS_CONFIG%
%|% MAIN Main
echo.
			set | find /C /V ""
%|% MAIN Main
%|% MAIN Main
%|% MAIN Main
%|% MAIN Main
%|% MAIN Main
%|% MAIN Main
%|% MAIN Main
set
			set | find /C /V ""
%-|%

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		%|% NS New t  %%.Mal
		%|% NS New t   %%.Mal2
		%|% NS Link %%.Mal t %%.Mal2
			set | find /C /V ""
		%<-% %%.Mal2
	)
%-|%

:MAIN_Read _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Eval _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Print _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%|% IO WriteEscapedLineVar %%.Mal
		%<-% _
	)
%-|%

:MAIN_REP _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%|% MAIN Read %%.Mal %->% %%.Mal
		%|% MAIN Eval %%.Mal %->% %%.Mal
		%|% MAIN Print %%.Mal
		%<-% _
	)
%-|%