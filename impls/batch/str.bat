@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:New -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=0"
		!_C_Return! %%.Str
	)
exit /b 0

:FromVar _Var -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=!%~1!"
		!_C_Return! %%.Str
	)
exit /b 0

:FromVal _Val -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=%~1"
		!_C_Return! %%.Str
	)
exit /b 0

:AppendStr _Str _NewStr -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		!_C_Copy! !%~2!.LineCount %%.LineCount2
		if !%%.LineCount! geq 1 (
			if !%%.LineCount2! geq 1 (
				!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.Line
				!_C_Copy! !%~2!.Line[1] %%.Line2
				set "!%~1!.Line[!%%.LineCount!]=!%%.Line!!%%.Line2!"
			)
		)
		for /l %%i in (2 1 !%%.LineCount2!) do (
			set /a %%.LineCount += 1
			!_C_Copy! !%~2!.Line[%%i] !%~1!.Line[!%%.LineCount!]
		)
		!_C_Copy! %%.LineCount !%~1!.LineCount
		!_C_Return! _
	)
exit /b 0

:AppendVal _Str _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!%~2"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=%~2"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		!_C_Return! _
	)
exit /b 0

:AppendVar _Str _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!!%~2!"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=!%~2!"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
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