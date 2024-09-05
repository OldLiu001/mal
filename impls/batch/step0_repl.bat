@REM v0.6

@echo off & pushd "%~dp0" & setlocal ENABLEDELAYEDEXPANSION
call :Init
!_C_Invoke! :Main
exit /b 0


:Main
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._Prompt=user> " & !_C_Invoke! IO.bat :WriteVar %%._Prompt
		!_C_Invoke! IO.bat :ReadEscapedLine & !_C_GetRet! %%._Input
		!_C_Invoke! :REP %%._Input
	)
goto :Main

:Read _MalCode -> _MalCode
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._MalCode=!%~1!"
		!_C_Return! %%._MalCode
	)
exit /b 0

:Eval _MalCode -> _MalCode
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._MalCode=!%~1!"
		!_C_Return! %%._MalCode
	)
exit /b 0

:Print _MalCode -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._MalCode=!%~1!"
		!_C_Invoke! IO.bat :WriteEscapedLineVar %%._MalCode
		!_C_Return! _
	)
exit /b 0

:REP _MalCode -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._MalCode=!%~1!"
		
		!_C_Invoke! :Read %%._MalCode & !_C_GetRet! %%._MalCode
		!_C_Invoke! :Eval %%._MalCode & !_C_GetRet! %%._MalCode
		!_C_Invoke! :Print %%._MalCode
		!_C_Return! _
	)
exit /b 0

(
	@REM Version 1.0

	:Init
		set "_G_LEVEL=0"
		set "_G_TRACE=>%~nx0"
		set "_G_RET="
		set "_G_ERR="
		set "_C_Invoke=call :Invoke"
		set "_C_Copy=call :CopyVar"
		set "_C_GetRet=call :GetRet"
		set "_C_Return=call :Return"
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

	:CopyVar _VarFrom _VarTo -> _
		if not defined %~1 (
			2>&1 echo [!_G_TRACE!] '%~1' undefined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	exit /b 0
)