@REM v:1.4

@echo off & pushd "%~dp0" & setlocal ENABLEDELAYEDEXPANSION
call :Init
!_C_Invoke! :Main
exit /b 0

:Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Prompt=user> " & !_C_Invoke! IO.bat :WriteVar %%.Prompt
		!_C_Invoke! IO.bat :ReadEscapedLine
		if defined _G_RET (
			!_C_GetRet! %%.Input
		) else (
			goto :Main
		)
		
		!_C_Invoke! Str.bat :FromVar %%.Input & !_C_GetRet! %%.Str

		!_C_Invoke! :REP %%.Str
		if defined _G_ERR (
			if "!_G_ERR.Type!" == "Exception" (
				!_C_Invoke! IO.bat :WriteErrLineVar _G_ERR.Msg
			) else if "!_G_ERR.Type!" == "Empty" (
				rem do nothing.
			) else (
				!_C_Fatal! "Error type '!_G_ERR.Type!' not support."
			)

			for /f "delims==" %%a in (
				'set _G_ERR 2^>nul'
			) do set "%%a="
		)
		
		!_C_Invoke! NS.bat :Free %%.Str
	)
goto :Main

:Read _StrMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		!_C_Invoke! Reader.bat :ReadString %%.StrMal & !_C_GetRet! %%.ObjMal
		if defined _G_ERR exit /b 0

		!_C_Return! %%.ObjMal
	)
exit /b 0

:Eval _ObjMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		!_C_Return! %%.ObjMal
	)
exit /b 0

:Print _ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		!_C_Invoke! Printer.bat :PrintMalType %%.ObjMal & !_C_GetRet! %%.StrMal
		
		!_C_Invoke! IO.bat :WriteStr %%.StrMal

		!_C_Invoke! NS.bat :Free %%.StrMal

		!_C_Return! _
	)
exit /b 0

:REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		!_C_Invoke! :Read %%.Mal & !_C_GetRet! %%.Mal
		if defined _G_ERR exit /b 0
		!_C_Invoke! :Eval %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! :Print %%.Mal
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