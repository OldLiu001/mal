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
	@REM Version 0.9
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

	:CopyVar _VarFrom _VarTo -> _
		if not defined %~1 (
			2>&1 echo [!_G_TRACE!] '%~1' undefined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	exit /b 0
)