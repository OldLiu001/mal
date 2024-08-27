@REM v:0.4, WriteStr untested


@REM Module Name: IO

@rem Export Functions:
@REM 	:ReadEscapedLine
@REM 	:WriteEscapedLineVar _Var
@REM 	:WriteVal _Val
@REM 	:WriteVar _Var
@REM 	:WriteLineVal _Val
@REM 	:WriteErrVal _Val
@REM 	:WriteErrLineVal _Val

@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0

:ReadEscapedLine
	for /f "delims=" %%a in (
		'call Readline.bat'
	) do set "_L{!_G_LEVEL!}_Input=%%~a"
	!_C_Copy! _L{!_G_LEVEL!}_Input _G_RET
	!_C_Clear!
exit /b 0

:WriteEscapedLineVar _Var
	if not defined %~1 (
		2>&1 echo [!_G_TRACE!] '%~1' undefined.
	)
	echo."!%~1!"| call WriteAll.bat
exit /b 0

:WriteVal _Val
	<nul set /p "=%~1"
exit /b 0

:WriteVar _Var
	if not defined %~1 (
		2>&1 echo [!_G_TRACE!] '%~1' undefined.
	)
	<nul set /p "=!%~1!"
exit /b 0

:WriteStr _Str
	set "_L{!_G_LEVEL!}_Str=!%~1!"
	for /f "delims=" %%a in ("_L{!_G_LEVEL!}_Str") do (
		for /f "delims=" %%b in ("!%%a!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				call :CopyVar !%%a!.Line[%%i] _L{!_G_LEVEL!}_Line
				call :WriteEscapedLineVar _L{!_G_LEVEL!}_Line
			)
		)
	)

	set "_G_RET="
	!_C_Clear!
exit /b 0

(
	@REM Version 0.5
	:Invoke
		if not defined _G_TRACE (
			set "_G_TRACE=>"
		)

		set "_G_TRACE_{!_G_LEVEL!}=!_G_TRACE!"
		
		set "_G_TMP=%~1"
		if /i "!_G_TMP:~,1!" Equ ":" (
			set "_G_TRACE=!_G_TRACE!>%~1"
		) else (
			set "_G_TRACE=!_G_TRACE!>%~1>%~2"
		)
		set "_G_TMP="
		
		set /a _G_LEVEL += 1
		call %*
		set /a _G_LEVEL -= 1
		
		!_C_Copy! _G_TRACE_{!_G_LEVEL!} _G_TRACE
		set "_G_TRACE_{!_G_LEVEL!}="
	exit /b 0

	:CopyVar _VarFrom _VarTo
		if not defined %~1 (
			2>&1 echo [!_G_TRACE!] '%~1' undefined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	exit /b 0
	
	:ClearLocalVars
		for /f "delims==" %%a in (
			'set _L{!_G_LEVEL!}_ 2^>nul'
		) do set "%%a="
	exit /b 0
)
