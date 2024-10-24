@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:TYPES_NewMal _ValType _ValValue -> _ObjMal
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

:TYPES_NewBatFn _Mod _Name _AutoEval -> _MalFn
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mod=%~1"
		set "%%.Name=%~2"
		if "%~3" == "False" (
			set "%%.AutoEval=False"
		) else (
			set "%%.AutoEval=True"
		)

		!_C_Invoke! NS New MalFn & !_C_GetRet! %%.MalFn
		set "!%%.MalFn!.SubType=BAT"
		set "!%%.MalFn!.Mod=!%%.Mod!"
		set "!%%.MalFn!.Name=!%%.Name!"
		set "!%%.MalFn!.AutoEval=!%%.AutoEval!"
		!_C_Return! %%.MalFn
	)
exit /b 0

:TYPES_FreeMalType _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		if not defined !%%.Mal! (
			exit /b 0
		)
		!_C_Copy! !%%.Mal!.Type %%.Type
		if "!%%.Type!" == "MalBool" (
			!_C_Invoke! NS Free %%.Mal
		) else if "!%%.Type!" == "MalNil" (
			!_C_Invoke! NS Free %%.Mal
		) else if "!%%.Type!" == "MalNum" (
			!_C_Invoke! NS Free %%.Mal
		) else if "!%%.Type!" == "MalSym" (
			!_C_Invoke! NS Free %%.Mal
		) else if "!%%.Type!" == "MalKwd" (
			!_C_Invoke! NS Free %%.Mal
		) else if "!%%.Type!" == "MalStr" (
			!_C_Invoke! NS Free %%.Mal
		) else if "!%%.Type!" == "MalLst" (
			!_C_Invoke! TYPES FreeMalListOrVec %%.Mal
		) else if "!%%.Type!" == "MalVec" (
			!_C_Invoke! TYPES FreeMalListOrVec %%.Mal
		) else if "!%%.Type!" == "MalMap" (
			!_C_Invoke! TYPES FreeMalMap %%.Mal
		) else if "!%%.Type!" == "MalFn" (
			!_C_Invoke! TYPES FreeMalFn %%.Mal
		) else (
			!_C_Fatal! "Arg _Mal is not a valid Mal type."
		)
	)
exit /b 0

:TYPES_FreeMalListOrVec _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Type %%.Type
		if "!%%.Type!" neq "MalLst" if "!%%.Type!" neq "MalVec" (
			!_C_Fatal! "Arg _Mal is not a MalLst or MalVec."
		)
		for /f "delims==" %%i in ('set !%%.Mal!.Item 2^>nul') do (
			!_C_Invoke! TYPES FreeMalType %%i
		)
		!_C_Invoke! NS Free %%.Mal
	)
goto :eof

:TYPES_FreeMalMap _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Type %%.Type
		if "!%%.Type!" neq "MalMap" (
			!_C_Fatal! "Arg _Mal is not a MalMap."
		)
		if defined !%%.Mal!.RawKeys (
			!_C_Invoke! NS Free !%%.Mal!.RawKeys
		)
		for /f "delims==" %%i in ('set !%%.Mal!.Item 2^>nul') do (
			set "%%.Var=%%i"
			if "!%%.Var:~-4!" == ".Key" (
				!_C_Invoke! TYPES FreeMalType %%i
			) else if "!%%.Var:~-6!" == ".Value" (
				!_C_Invoke! TYPES FreeMalType %%i
			)
		)
		!_C_Invoke! NS Free %%.Mal
	)
exit /b 0

:TYPES_FreeMalFn _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Type %%.Type
		if "!%%.Type!" neq "MalFn" (
			!_C_Fatal! "Arg _Mal is not a MalFn."
		)
		!_C_Invoke! NS Free %%.Mal
	)
exit /b 0

:TYPES_CheckType _Var _Type1 _Type2 ... -> _Bool
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Bool=False"
		!_C_Copy! !%~1!.Type %%.Type
	)
	:TYPES_CheckType_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" neq "" (
			if "%~1" equ "!%%.Type!" (
				set "%%.Bool=True"
			)
			shift
			goto TYPES_CheckType_Loop
		)
		!_C_Return! %%.Bool
	)
exit /b 0

:TYPES_CopyMalType _Mal -> _ClonedMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Type %%.Type
		if "!%%.Type!" == "MalFn" (
			!_C_Copy! !%%.Mal!.SubType %%.SubType
			if "!%%.SubType!" == "BAT" (
				!_C_Copy! !%%.Mal!.Mod %%.Mod
				!_C_Copy! !%%.Mal!.Name %%.Name
				!_C_Copy! !%%.Mal!.AutoEval %%.AutoEval
				!_C_Invoke! Types NewBatFn !%%.Mod! !%%.Name! !%%.AutoEval! & !_C_GetRet! %%.ClonedMal
			) else (
				!_C_Fatal! "Not implemented yet."
			)
		) else if "!%%.Type!" == "MalNum" (
			!_C_Copy! !%%.Mal!.Value %%.Val
			!_C_Invoke! Types NewMal MalNum !%%.Val!
			!_C_GetRet! %%.ClonedMal
		) else (
			!_C_Fatal! "Not implemented yet."
		)
		!_C_Return! %%.ClonedMal
	)
exit /b 0
	