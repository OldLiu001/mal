@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:TYPES_NewMal _Type _Value -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ValType=%~1"
		set "%%.ValValue=%~2"
		%|% NS New !%%.ValType! %->% %%.ObjMal
		%&% %%.ValValue !%%.ObjMal!.Value
		%<-% %%.ObjMal
	)
%-|%

:TYPES_NewMalList Var1 Var2 ... -> MalList
	for %%. in (_L{!_G_LEVEL!}_) do (
		%|% NS New MalLst %->% %%.ObjMal
		set "%%.Count=0"
	)
	:TYPES_NewMalList_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			%|% NS Link %%.ObjMal Item[!%%.Count!] %~1
			%|% NS Free %~1
			shift
			goto TYPES_NewMalList_Loop
		)
		%&% %%.Count !%%.ObjMal!.Count
		%<-% %%.ObjMal
	)
%-|%

:TYPES_NewBatFn _Mod _Name [_AutoEval=True] -> MalFn
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mod=%~1"
		set "%%.Name=%~2"
		if "%~3" == "False" (
			set "%%.AutoEval=False"
		) else (
			set "%%.AutoEval=True"
		)

		%|% NS New MalFn %->% %%.MalFn
		set "!%%.MalFn!.SubType=BAT"
		set "!%%.MalFn!.Mod=!%%.Mod!"
		set "!%%.MalFn!.Name=!%%.Name!"
		set "!%%.MalFn!.AutoEval=!%%.AutoEval!"
		%<-% %%.MalFn
	)
%-|%

:TYPES_FreeMalType Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."
	)
%-|%

:TYPES_FreeMalListOrVec Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."
	)
goto :eof

:TYPES_FreeMalMap Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."
	)
%-|%

:TYPES_FreeMalFn Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."
	)
%-|%

:TYPES_CheckType &Var _Type1 _Type2 ... -> _Bool
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Bool=False"
		%&% !%~1!.Type %%.Type
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
		%<-% %%.Bool
	)
%-|%

:TYPES_CopyMalType &Mal -> ClonedMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."
	)
%-|%
	