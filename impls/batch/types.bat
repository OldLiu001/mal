@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0


:TYPES_NewMalAtom _ValType _ValValue -> _ObjMalAtom
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ValType=%~1"
		set "%%.ValValue=%~2"
		!_C_Invoke! NS New !%%.ValType! & !_C_GetRet! %%.ObjMal
		!_C_Copy! %%.ValValue !%%.ObjMal!.Value
		!_C_Return! %%.ObjMal
	)
exit /b 0

:TYPES_NewMalList _Var1 _Var2 ... -> _ObjMalList
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS New MalLst & !_C_GetRet! %%.ObjMal
		set "%%.Count=0"
	)
	:TYPES_NewMalList_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			!_C_Copy! %~1 !%%.ObjMal!.Item[!%%.Count!]
			shift
			goto TYPES_NewMalList_Loop
		)
		!_C_Copy! %%.Count !%%.ObjMal!.Count
		!_C_Return! %%.ObjMal
	)
exit /b 0