@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:IO_ReadEscapedLine -> _Line
	for %%. in (_L{!_G_LEVEL!}_) do (
		if not defined MAL_BATCH_IMPL_SINGLE_FILE (
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
			%|% IO WriteEscapedLineVar %%.Line
		)
		%<-% %%.Line
	)
%-|%

:IO_WriteEscapedLineVar _Var
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			%?|% "Arg 'Var' is empty."
		)
		if not defined !%%.Var! (
			%?|% "Arg '!%%.Var!' undefined."
		)
		%&% !%%.Var! %%.Var
		if not defined MAL_BATCH_IMPL_SINGLE_FILE (
			echo."!%%.Var!"| call WRITEALL
		) else (
			echo."!%%.Var!"| call "%~s0" CALL_WRITEALL
		)
		%<-% _
	)
%-|%

:IO_WriteVal _Val
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Val=%~1"
		<nul set /p "=!%%.Val!"
		%<-% _
	)
%-|%

:IO_WriteVar _Var
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			%?|% "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			%?|% "'!%%.Var!' undefined."
		)
		%&% !%%.Var! %%.Var
		<nul set /p "=!%%.Var!"
		%<-% _
	)
%-|%

:IO_WriteStr &Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Str=!%~1!"
		for /f "delims=" %%b in ("!%%.Str!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				%&% !%%.Str!.Line[%%i] %%.Line
				%|% IO WriteEscapedLineVar %%.Line
			)
		)

		%<-% _
	)
%-|%

:IO_WriteErrLineVal _Val
	for %%. in (_L{!_G_LEVEL!}_) do (
		if defined MAL_BATCH_IMPL_NO_STDERR (
			echo.%~1
		) else (
			2>&1 echo.%~1
		)
		%<-% _
	)
%-|%

:IO_WriteErrLineVar _Var
	for %%. in (_L{!_G_LEVEL!}_) do (
		if defined MAL_BATCH_IMPL_NO_STDERR (
			echo.!%~1!
		) else (
			2>&1 echo.!%~1!
		)
		%<-% _
	)
%-|%