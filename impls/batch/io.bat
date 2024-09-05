@REM v:1.1

@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0

:ReadEscapedLine _ -> _EscapedLine
	for %%. in (_L{!_G_LEVEL!}) do (
		for /f "delims=" %%a in (
			'call Readline.bat'
		) do (
			set "%%._EscapedLine=%%~a"
		)
		set %%._EscapedLine
		!_C_Return! %%._EscapedLine
	)
exit /b 0

:WriteEscapedLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._Var=%~1"
		if "!%%._Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%._Var! (
			!_C_Fatal! "'!%%._Var!' undefined."
		)
		!_C_Copy! !%%._Var! %%._Var
		echo."!%%._Var!"| call WriteAll.bat
		!_C_Return! _
	)
exit /b 0

:WriteVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._Val=%~1"
		<nul set /p "=!%%._Val!"
		!_C_Return! _
	)
exit /b 0

:WriteVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._Var=%~1"
		if "!%%._Var!" == "" (
			!_C_Fatal! "Arg _Var is empty."
		)
		if not defined !%%._Var! (
			!_C_Fatal! "'!%%._Var!' undefined."
		)
		!_C_Copy! !%%._Var! %%._Var
		<nul set /p "=!%%._Var!"
		!_C_Return! _
	)
exit /b 0

:WriteStr _Str -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._Str=!%~1!"
		for /f "delims=" %%b in ("!%%._Str!.LineCount") do (
			for /l %%i in (1 1 !%%b!) do (
				!_C_Copy! !%%._Str!.Line[%%i] %%._Line
				!_C_Invoke! :WriteEscapedLineVar %%._Line
			)
		)

		!_C_Return! _
	)
exit /b 0

:WriteErrLineVal _Val -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		2>&1 echo.%~1
		!_C_Return! _
	)
exit /b 0

:WriteErrLineVar _Var -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		2>&1 echo.!%~1!
		!_C_Return! _
	)
exit /b 0

(
	@REM Version 1.1

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
		2>&1 echo [!_G_TRACE!] %~1
		pause & exit 1
	exit /b 0

	:CopyVar _VarFrom _VarTo -> _
		if not defined %~1 (
			!_C_Fatal! "'%~1' undefined."
		)
		set "%~2=!%~1!"
	exit /b 0
)