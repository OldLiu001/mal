@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			2>con >&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		2>con >&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:TYPES_NewMal _Type _Value -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Type=%~1"
		set "%%.Value=%~2"
		%{n% %%.Mal %}
		%{s% %%.Mal Type !%%.Type! %}
		%{s% %%.Mal Value !%%.Value! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewMalList Mal1 Mal2 ... -> MalList
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Mal %}
		%{s% %%.Mal Type MalLst %}
		set "%%.Count=0"
	)
	:TYPES_NewMalList_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			%{s% %%.Mal Item[!%%.Count!] %~1 %}
			shift
			goto TYPES_NewMalList_Loop
		)
		%{s% %%.Mal Count !%%.Count! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewMalVec Mal1 Mal2 ... -> MalVec
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Mal %}
		%{s% %%.Mal Type MalVec %}
		set "%%.Count=0"
	)
	:TYPES_NewMalVec_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			%{s% %%.Mal Item[!%%.Count!] %~1 %}
			shift
			goto TYPES_NewMalVec_Loop
		)
		%{s% %%.Mal Count !%%.Count! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewMalMap -> MalMap
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Mal %}
		%{s% %%.Mal Type MalMap %}
		set "%%.Count=0"
		set "%%.RawKeyCount=0"
		%{n% %%.RawKeys %}
		%{s% %%.Mal RawKeys !%%.RawKeys! %}
		%{s% %%.Mal Count !%%.Count! %}
		%{s% %%.Mal RawKeyCount !%%.RawKeyCount! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewBatFn _Mod _Name [_AutoEval=True] -> MalFn
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mod=%~1"
		set "%%.Name=%~2"
		if "%~3" == "False" (
			set "%%.AutoEval=False"
		) else (
			set "%%.AutoEval=True"
		)

		%{n% %%.MalFn %}
		%{s% %%.MalFn Type MalFn %}
		%{s% %%.MalFn SubType BAT %}
		%{s% %%.MalFn Mod !%%.Mod! %}
		%{s% %%.MalFn Name !%%.Name! %}
		%{s% %%.MalFn AutoEval !%%.AutoEval! %}
		%<-% %%.MalFn
	)
%-|%

:TYPES_NewMalFn _Binds _Body _Env -> MalFn
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.MalFn %}
		%{s% %%.MalFn Type MalFn %}
		%{s% %%.MalFn SubType MAL %}
		%{s% %%.MalFn AutoEval True %}
		%{s% %%.MalFn Binds %~1 %}
		%{s% %%.MalFn Body %~2 %}
		%{s% %%.MalFn Env %~3 %}
		%<-% %%.MalFn
	)
%-|%

:TYPES_CheckType &Mal _Type1 _Type2 ... -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Bool=0"
		%{g% "%~1" Type %%.Type %}
	)
	:TYPES_CheckType_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "%~1" neq "" (
			if "%~1" equ "!%%.Type!" (
				set "%%.Bool=1"
			)
			shift
			goto TYPES_CheckType_Loop
		)
		%<-% %%.Bool
	)
%-|%

:TYPES_CopyMal &Mal -> ClonedMal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" Type %%.Type %}
		if "!%%.Type!" == "MalNum" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalNum "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalSym" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalSym "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalNil" (
			%{% TYPES NewMal MalNil nil %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalBool" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalBool "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalKwd" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalKwd "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalStr" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalStr "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalLst" (
			%{g% "%~1" Count %%.Count %}
			%{% TYPES NewMalList %}% %->% %%.Ret
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.Item %}
				%{% TYPES CopyMal "!%%.Item!" %}% %->% %%.NewItem
				%{s% %%.Ret Item[%%i] !%%.NewItem! %}
			)
			%{s% %%.Ret Count !%%.Count! %}
		) else if "!%%.Type!" == "MalVec" (
			%{g% "%~1" Count %%.Count %}
			%{% TYPES NewMalVec %}% %->% %%.Ret
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.Item %}
				%{% TYPES CopyMal "!%%.Item!" %}% %->% %%.NewItem
				%{s% %%.Ret Item[%%i] !%%.NewItem! %}
			)
			%{s% %%.Ret Count !%%.Count! %}
		) else if "!%%.Type!" == "MalMap" (
			%{% TYPES NewMalMap %}% %->% %%.Ret
			%{g% "%~1" RawKeyCount %%.RKCount %}
			%{g% "%~1" RawKeys %%.RawKeys %}
			set "%%.MapCnt=0"
			for /l %%i in (1 1 !%%.RKCount!) do (
				%{g% "!%%.RawKeys!" Key[%%i] %%.RawKey %}
				%{g% "%~1" Item[!%%.RawKey!].Count %%.SameCnt %}
				for /l %%j in (1 1 !%%.SameCnt!) do (
					%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Key %%.KeyMal %}
					%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Value %%.ValMal %}
					%{% TYPES CopyMal "!%%.KeyMal!" %}% %->% %%.NewKey
					%{% TYPES CopyMal "!%%.ValMal!" %}% %->% %%.NewVal
					%{g% "!%%.NewKey!" Value %%.RawK %}
					if not "!%%.RawK!" == "" (
						%{g% "%~1" Item[!%%.RawK!].Count %%.ExistCnt %}
						if "!%%.ExistCnt!" == "" (
							set /a %%.MapCnt += 1
							%{s% %%.Ret Item[!%%.RawK!].Count 1 %}
							%{s% %%.Ret Item[!%%.RawK!].Item[1].Key !%%.NewKey! %}
							%{s% %%.Ret Item[!%%.RawK!].Item[1].Value !%%.NewVal! %}
							%{s% "!%%.RawKeys!" Key[!%%.MapCnt!] !%%.RawK! %}
						)
					)
				)
			)
			%{s% %%.Ret Count !%%.MapCnt! %}
			%{s% %%.Ret RawKeyCount !%%.MapCnt! %}
			%{s% %%.Ret RawKeys !%%.RawKeys! %}
		) else if "!%%.Type!" == "MalFn" (
			%{g% "%~1" SubType %%.SubType %}
			if "!%%.SubType!" == "BAT" (
				%{g% "%~1" Mod %%.Mod %}
				%{g% "%~1" Name %%.Name %}
				%{g% "%~1" AutoEval %%.AutoEval %}
				%{% TYPES NewBatFn "!%%.Mod!" "!%%.Name!" "!%%.AutoEval!" %}% %->% %%.Ret
			) else (
				%{g% "%~1" Binds %%.Binds %}
				%{g% "%~1" Body %%.Body %}
				%{g% "%~1" Env %%.Env %}
				%{% TYPES NewMalFn "!%%.Binds!" "!%%.Body!" "!%%.Env!" %}% %->% %%.Ret
			)
		) else (
			%?|% "Unknown type '!%%.Type!' for copy."
		)
		%<-% %%.Ret
	)
%-|%

:TYPES_SameObjects &Mal1 &Mal2 -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if "!%~1!" == "!%~2!" (
			%<-% 1
			%-|%
		)
		%<-% 0
	)
%-|%
