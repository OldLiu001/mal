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
				
				%|% Str FromVar %%.Input %->% %%.Str
				
				%|% MAIN REP %%.Str
				%?% (
					if "!_G_ERR.Type!" == "Exception" (
						%|% IO WriteErrLineVar _G_ERR.Msg
					) else if "!_G_ERR.Type!" == "Empty" (
						rem do nothing.
					) else (
						%?|% "Error type '!_G_ERR.Type!' not support."
					)

					for /f "delims==" %%a in (
						'set _G_ERR 2^>nul'
					) do set "%%a="
				)
				
				%|% NS Free %%.Str
			)
		)
	)
%-|%

:MAIN_Read StrMal -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		%|% Reader ReadString %%.StrMal %->% %%.ObjMal
		%?% %-|%

		%<-% %%.ObjMal
	)
%-|%

:MAIN_Eval ObjMal -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		%<-% %%.ObjMal
	)
%-|%

:MAIN_Print ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		%|% Printer PrintMalType %%.ObjMal %->% %%.StrMal

		%|% TYPES FreeMalType %%.ObjMal
		
		%|% IO WriteStr %%.StrMal

		%|% NS Free %%.StrMal

		%<-% _
	)
%-|%

:MAIN_REP Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		%|% MAIN Read %%.Mal %->% %%.Mal
		%?% %-|%
		%|% MAIN Eval %%.Mal %->% %%.Mal
		%|% MAIN Print %%.Mal
		%<-% _
	)
%-|%