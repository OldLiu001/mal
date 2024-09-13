@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:IO_ReadEscapedLine _ -> _Line
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /f "delims=" %%a in (
			'call Readline.bat'
		) do (
			set "%%.Line=%%~a"
		)
		!_C_Return! %%.Line
	)
exit /b 0

:IO_WriteEscapedLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			!_C_Fatal! "'!%%.Var!' undefined."
		)
		!_C_Copy! !%%.Var! %%.Var
		echo."!%%.Var!"| call WriteAll.bat
		!_C_Return! _
	)
exit /b 0

:IO_WriteVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Val=%~1"
		<nul set /p "=!%%.Val!"
		!_C_Return! _
	)
exit /b 0

:IO_WriteVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Var=%~1"
		if "!%%.Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%.Var! (
			!_C_Fatal! "'!%%.Var!' undefined."
		)
		!_C_Copy! !%%.Var! %%.Var
		<nul set /p "=!%%.Var!"
		!_C_Return! _
	)
exit /b 0

:IO_WriteStr _Str -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Str=!%~1!"
		for /f "delims=" %%b in ("!%%.Str!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				!_C_Copy! !%%.Str!.Line[%%i] %%.Line
				!_C_Invoke! IO WriteEscapedLineVar %%.Line
			)
		)

		!_C_Return! _
	)
exit /b 0

:IO_WriteErrLineVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.%~1
		!_C_Return! _
	)
exit /b 0

:IO_WriteErrLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.!%~1!
		!_C_Return! _
	)
exit /b 0