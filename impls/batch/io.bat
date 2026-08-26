@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			>&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		>&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:IO_ReadEncLine -> Line
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.PACKED (
			for /f "tokens=* eol=" %%a in (
				'call READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		) else (
			for /f "tokens=* eol=" %%a in (
				'call "%~s0" CALL_READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		)

		if defined MAL_BATCH_IMPL_ECHO_STDIN (
			%{% IO WriteEncLine %%.Line %}%
		)

		%<-% %%.Line
	)
%-|%

:IO_WriteEncLine Line
	for %%. in (_L[!_G.LEVEL!].) do (
		if defined %~1 (
			if not defined _G.PACKED (
				echo."!%~1!"| call WRITEALL
			) else (
				echo."!%~1!"| call "%~s0" CALL_WRITEALL
			)
		) else (
			echo.
		)
	)
%-|%

:IO_WriteVal Val
	for %%. in (_L[!_G.LEVEL!].) do (
		<nul set /p "=%~1"
	)
%-|%

:IO_WriteVar Var
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if "%~1" == "" %?|% "Arg 'Var' is empty."
		<nul set /p "=!%~1!"
	)
%-|%

:IO_WriteStr
	for %%. in (_L[!_G.LEVEL!].) do (
		%?|% TODO
	)
%-|%

:IO_WriteErrLineVal Val
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.V=%~1"
		if defined MAL_BATCH_IMPL_NO_STDERR (
			echo.!%%.V!
		) else (
			2>&1 echo.!%%.V!
		)
	)
%-|%

:IO_WriteErrLineVar _Var
	for %%. in (_L[!_G.LEVEL!].) do (
		if defined MAL_BATCH_IMPL_NO_STDERR (
			echo.!%~1!
		) else (
			2>&1 echo.!%~1!
		)
	)
%-|%
:UTIL_SetRet

	if defined _G.NSUTIL (

		call set "_T.SR.Type=%%!%~1!.Type%%"

		if /i "!_T.SR.Type!" == "NSMeta" (

			if defined _G.LEVEL[!_G.LEVEL!][!%~1!] (

				set "_G.LEVEL[!_G.LEVEL!][!%~1!]="

				set /a "_T.SR.PrevLevel = _G.LEVEL - 1"

				set "_G.RET=!%~1!"

				set "_G.LEVEL[!_T.SR.PrevLevel!][!_G.RET!]=!_G.RET!"

			) else (

				set "_G.RET=!%~1!"

			)

		) else (

			set "_G.RET=!%~1!"

		)

	) else (

		set "_G.RET=!%~1!"

	)

exit /b 0



:UTIL_GetRet

	if not defined _G.ERR (

		set "%~1=!_G.RET!"

	)

	set "_G.RET="

exit /b 0

