@REM v:1.4

@echo off
call %* || !_C_Fatal! "Call '%~nx0' failed."
exit /b 0

:ReadEscapedLine _ -> _Line
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /f "delims=" %%a in (
			'call Readline.bat'
		) do (
			set "%%.Line=%%~a"
		)
		!_C_Return! %%.Line
	)
exit /b 0

:WriteEscapedLineVar _Var -> _
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

:WriteVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Val=%~1"
		<nul set /p "=!%%.Val!"
		!_C_Return! _
	)
exit /b 0

:WriteVar _Var -> _
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

:WriteStr _Str -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Str=!%~1!"
		for /f "delims=" %%b in ("!%%.Str!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				!_C_Copy! !%%.Str!.Line[%%i] %%.Line
				!_C_Invoke! :WriteEscapedLineVar %%.Line
			)
		)

		!_C_Return! _
	)
exit /b 0

:WriteErrLineVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.%~1
		!_C_Return! _
	)
exit /b 0

:WriteErrLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		2>&1 echo.!%~1!
		!_C_Return! _
	)
exit /b 0

(
	@REM Version 1.4

	:Init
		set "_G_LEVEL=0"
		set "_G_TRACE=>%~nx0"
		set "_G_RET="
		set "_G_ERR="

		set "_C_Invoke=call :Invoke"
		set "_C_Copy=call :CopyVar"
		set "_C_GetRet=call :GetRet"
		set "_C_Return=call :Return"
		set "_C_Fatal=call :Fatal"
		set "_C_Throw=call :Throw"
	exit /b 0

	:Invoke * -> *
		set /a _G_LEVEL = _G_LEVEL
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
		
		set "_G_RET="
		set /a _G_LEVEL += 1

		call %*
		
		for /f "delims==" %%a in (
			'set _L{!_G_LEVEL!}_ 2^>nul'
		) do set "%%a="

		set /a _G_LEVEL -= 1
		
		!_C_Copy! _G_TRACE_{!_G_LEVEL!} _G_TRACE
		set "_G_TRACE_{!_G_LEVEL!}="
	exit /b 0

	:GetRet _Var -> _
		if not defined _G_ERR (
			!_C_Copy! _G_RET %~1
		)
		set _G_RET=
	exit /b 0

	:Return _Var -> _
		set _G_RET=
		if "%~1" neq "" if "%~1" neq "_" if defined %~1 (
			!_C_Copy! %~1 _G_RET
		)
	exit /b 0

	:Fatal _Msg
		>&2 echo [!_G_TRACE!] Fatal: %~1
		pause & exit 1
	exit /b 0

	:Throw _Type _Data _Msg
		set _G_ERR=_
		set "_G_ERR.Type=%~1"
		if "%~2" neq "_" set "_G_ERR.Data=!%~2!"
		set "_G_ERR.Msg=[!_G_TRACE!] !_G_ERR.Type!: %~3"
	exit /b 0

	:CopyVar _VarFrom _VarTo -> _
		if not defined %~1 (
			!_C_Fatal! "'%~1' undefined."
		)
		set "%~2=!%~1!"
	exit /b 0
)