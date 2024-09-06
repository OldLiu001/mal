@REM v:1.1

@echo off & pushd "%~dp0" & setlocal ENABLEDELAYEDEXPANSION
call :Init
!_C_Invoke! :Main
exit /b 0

:Main
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._Prompt=user> " & !_C_Invoke! IO.bat :WriteVar %%._Prompt
		!_C_Invoke! IO.bat :ReadEscapedLine & !_C_GetRet! %%._Input
		
		!_C_Invoke! Str.bat :FromVar %%._Input & !_C_GetRet! %%._Str

		!_C_Invoke! :REP %%._Str
		if defined _G_ERR (
			if "!_G_ERR.Type!" == "Exception" (
				!_C_Invoke! IO.bat :WriteErrLineVar _G_ERR.Msg
			) else (
				!_C_Fatal! "Error type '!_G_ERR.Type!' not support."
			)

			for /f "delims==" %%a in (
				'set _G_ERR 2^>nul'
			) do set "%%a="
		)
		
		!_C_Invoke! NS.bat :Free %%._Str
	)
goto :Main

:Read _StrMalCode -> _ObjMalCode
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._StrMalCode=!%~1!"
		
		!_C_Invoke! Reader.bat :ReadString %%._StrMalCode & !_C_GetRet! %%._ObjMalCode
		if defined _G_ERR exit /b 0

		!_C_Return! %%._ObjMalCode
	)
exit /b 0

:Eval _ObjMalCode -> _ObjMalCode
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._ObjMalCode=!%~1!"
		!_C_Return! %%._ObjMalCode
	)
exit /b 0

:Print _ObjMalCode -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._ObjMalCode=!%~1!"
		
		!_C_Invoke! Printer.bat :PrintMalType %%._ObjMalCode & !_C_GetRet! %%._StrMalCode
		
		!_C_Invoke! IO.bat :WriteStr %%._StrMalCode

		!_C_Invoke! NS.bat :Free %%._StrMalCode

		!_C_Return! _
	)
exit /b 0

:REP _MalCode -> _
	for %%. in (_L{!_G_LEVEL!}) do (
		set "%%._MalCode=!%~1!"
		
		!_C_Invoke! :Read %%._MalCode & !_C_GetRet! %%._MalCode
		if defined _G_ERR exit /b 0
		!_C_Invoke! :Eval %%._MalCode & !_C_GetRet! %%._MalCode
		!_C_Invoke! :Print %%._MalCode
		!_C_Return! _
	)
exit /b 0

(
	@REM Version 1.3

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
		>&2 echo [!_G_TRACE!] %~1
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