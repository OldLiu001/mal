@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:TYPES_NewMal _ValType _ValValue -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ValType=%~1"
		set "%%.ValValue=%~2"
		%|% NS New !%%.ValType! %->% %%.ObjMal
		%&% %%.ValValue !%%.ObjMal!.Value
		%<-% %%.ObjMal
	)
%-|%

:TYPES_NewMalList _Var1 _Var2 ... -> _ObjMalList
	for %%. in (_L{!_G_LEVEL!}_) do (
		%|% NS New MalLst %->% %%.ObjMal
		set "%%.Count=0"
	)
	:TYPES_NewMalList_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			%|% NS Link %%.ObjMal Item[!%%.Count!] %~1
			shift
			goto TYPES_NewMalList_Loop
		)
		%&% %%.Count !%%.ObjMal!.Count
		%<-% %%.ObjMal
	)
%-|%

:TYPES_NewBatFn _Mod _Name _AutoEval -> _MalFn
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

:TYPES_FreeMalType _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."


		set "%%.Mal=!%~1!"
		if not defined !%%.Mal! (
			%-|%
		)
		%&% !%%.Mal!.Type %%.Type
		if "!%%.Type!" == "MalBool" (
			%|% NS Free %%.Mal
		) else if "!%%.Type!" == "MalNil" (
			%|% NS Free %%.Mal
		) else if "!%%.Type!" == "MalNum" (
			%|% NS Free %%.Mal
		) else if "!%%.Type!" == "MalSym" (
			%|% NS Free %%.Mal
		) else if "!%%.Type!" == "MalKwd" (
			%|% NS Free %%.Mal
		) else if "!%%.Type!" == "MalStr" (
			%|% NS Free %%.Mal
		) else if "!%%.Type!" == "MalLst" (
			%|% TYPES FreeMalListOrVec %%.Mal
		) else if "!%%.Type!" == "MalVec" (
			%|% TYPES FreeMalListOrVec %%.Mal
		) else if "!%%.Type!" == "MalMap" (
			%|% TYPES FreeMalMap %%.Mal
		) else if "!%%.Type!" == "MalFn" (
			%|% TYPES FreeMalFn %%.Mal
		) else (
			%?|% "arg is not a valid Mal type."
		)
	)
%-|%

:TYPES_FreeMalListOrVec _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."

		
		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Type %%.Type
		if "!%%.Type!" neq "MalLst" if "!%%.Type!" neq "MalVec" (
			%?|% "arg is not a MalLst or MalVec."
		)
		set /a %%.RefCount = !%%.Mal!.RefCount
		if !%%.RefCount! leq 0 (
			for /f "delims==" %%i in ('set !%%.Mal!.Item 2^>nul') do (
				%|% TYPES FreeMalType %%i
			)
			%|% NS Free %%.Mal
		) else (
			set /a %%.RefCount -= 1
			%&% %%.RefCount !%%.Mal!.RefCount
		)
	)
goto :eof

:TYPES_FreeMalMap _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."

		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Type %%.Type
		if "!%%.Type!" neq "MalMap" (
			%?|% "Arg _Mal is not a MalMap."
		)
		if defined !%%.Mal!.RawKeys (
			%|% NS Free !%%.Mal!.RawKeys
		)
		for /f "delims==" %%i in ('set !%%.Mal!.Item 2^>nul') do (
			set "%%.Var=%%i"
			if "!%%.Var:~-4!" == ".Key" (
				%|% TYPES FreeMalType %%i
			) else if "!%%.Var:~-6!" == ".Value" (
				%|% TYPES FreeMalType %%i
			)
		)
		%|% NS Free %%.Mal
	)
%-|%

:TYPES_FreeMalFn _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."


		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Type %%.Type
		if "!%%.Type!" neq "MalFn" (
			%?|% "Arg _Mal is not a MalFn."
		)
		%&% !%%.Mal!.SubType %%.SubType
		if "!%%.SubType!" == "BAT" (
			%|% NS Free %%.Mal
		) else if "!%%.SubType!" == "MAL" (
			%|% Env Free !%%.Mal!.Env
			%|% Types FreeMalType !%%.Mal!.Binds
			%|% Types FreeMalType !%%.Mal!.Body
			%|% NS Free %%.Mal
		) else (
			%?|% "Reached an unexpected branch."
		)
	)
%-|%

:TYPES_CheckType _Var _Type1 _Type2 ... -> _Bool
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

:TYPES_CopyMalType _Mal -> _ClonedMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		%?|% "Deprecated."

		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Type %%.Type
		if "!%%.Type!" == "MalFn" (
			%&% !%%.Mal!.SubType %%.SubType
			if "!%%.SubType!" == "BAT" (
				%&% !%%.Mal!.Mod %%.Mod
				%&% !%%.Mal!.Name %%.Name
				%&% !%%.Mal!.AutoEval %%.AutoEval
				%|% Types NewBatFn !%%.Mod! !%%.Name! !%%.AutoEval! %->% %%.ClonedMal
			) else (
				%?|% "Not implemented yet."
			)
		) else if "!%%.Type!" == "MalNum" (
			%&% !%%.Mal!.Value %%.Val
			%|% Types NewMal MalNum !%%.Val!
			%|->% %%.ClonedMal
		) else if "!%%.Type!" == "MalBool" (
			%&% !%%.Mal!.Value %%.Val
			%|% Types NewMal MalBool !%%.Val!
			%|->% %%.ClonedMal
		) else if "!%%.Type!" == "MalNil" (
			%&% !%%.Mal!.Value %%.Val
			%|% Types NewMal MalNil !%%.Val!
			%|->% %%.ClonedMal
		) else if "!%%.Type!" == "MalLst" (
			set /a %%.RefCount = !%%.Mal!.RefCount + 1
			%&% %%.RefCount !%%.Mal!.RefCount
			%&% %%.Mal %%.ClonedMal
		) else (
			%?|% "Not implemented yet."
		)
		%<-% %%.ClonedMal
	)
%-|%
	