@REM v:0.6

@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0


:NewMalAtom _ValType _ValValue -> _ObjMalAtom
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ValType=%~1"
		set "_L{%%.}_ValValue=%~2"
		!_C_Invoke! NS.bat :New !_L{%%.}_ValType!
		!_C_Copy! _G_RET _L{%%.}_ObjMal
		!_C_Copy! _L{%%.}_ValValue !_L{%%.}_ObjMal!.Value
		!_C_Copy! _L{%%.}_ObjMal _G_RET
	)
exit /b 0

:NewMalList _Var1 _Var2 ... -> _ObjMalList
	for %%. in (!_G_LEVEL!) do (
		!_C_Invoke! NS.bat :New MalLst
		!_C_Copy! _G_RET _L{%%.}_ObjMal
		set "_L{%%.}_Count=0"
	)
	:NewMalList_Loop
	for %%. in (!_G_LEVEL!) do (
		if "%~1" neq "" (
			set /a _L{%%.}_Count += 1
			!_C_Copy! %~1 !_L{%%.}_ObjMal!.Item[!_L{%%.}_Count!]
			shift
			goto :NewMalList_Loop
		)
		!_C_Copy! _L{%%.}_Count !_L{%%.}_ObjMal!.Count
		!_C_Copy! _L{%%.}_ObjMal _G_RET
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