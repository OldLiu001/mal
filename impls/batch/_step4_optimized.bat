@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	call %2 %3 %4 %5 %6 %7 %8 %9 || %?|% "Call '%~nx0' failed."
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)

%{% MAIN Main %~1 %}%
%-|%

:MAIN_Main
	if not defined _G.ENV (
		%{% TYPES NewMalMap %}% %->% _G.ENV
		%{% MAIN RegisterBuiltins _G.ENV %}%
		%{% MAIN EncKey DEBUG-EVAL %}% %->% _G.DEBUGKEY
	)
	if "%~1" == "READALL" goto MAIN_ReadAll
	:MAIN_REPL_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Prompt=user> "
		%{% IO WriteVar %%.Prompt %}%
		%{% IO ReadEncLine %}% %->% %%.Input
		if defined %%.Input (
			call !_T.UTIL! :UTIL_Invoke MAIN REP %%.Input
			%?% (
				if "!_G.ERR.Type!" == "Exception" (
					call !_T.UTIL! :UTIL_Invoke IO WriteErrLineVar _G.ERR.Msg
				) else if "!_G.ERR.Type!" == "Empty" (
					rem do nothing.
				) else (
					%?|% "Error type '!_G.ERR.Type!' not support."
				)
				( set _G.ERR ) > "%TEMP%\mal_e_!_G.LEVEL!.txt" 2>nul
				for /f "usebackq delims==" %%a in ("%TEMP%\mal_e_!_G.LEVEL!.txt") do set "%%a="
			)
		) else (
			exit /b 0
		)
	)
	goto MAIN_REPL_Loop
%-|%

:MAIN_ReadAll
	for /f "tokens=* eol=" %%a in (
		'readall.bat RAW'
	) do (
		set "_M.RDALL.Line=%%a"
		if defined _G.DBG echo [RD_ALL got] %%a >&2
		%{% IO WriteVal "user> " %}%
		call !_T.UTIL! :UTIL_Invoke MAIN REP _M.RDALL.Line
		if defined _G.DBG echo [RD_done REP] %%a >&2
		%?% (
			if "!_G.ERR.Type!" == "Exception" (
				call !_T.UTIL! :UTIL_Invoke IO WriteErrLineVar _G.ERR.Msg
			)
			( set _G.ERR ) > "%TEMP%\mal_e_!_G.LEVEL!.txt" 2>nul
			for /f "usebackq delims==" %%b in ("%TEMP%\mal_e_!_G.LEVEL!.txt") do set "%%b="
		)
	)
	%<-% ""
%-|%

:MAIN_ReadAll_Encode Raw OutVar
	setlocal disabledelayedexpansion
	set "_ENC_RAW=%~1"
	set "_ENC_OUT="
	for /f "tokens=* eol=" %%b in (
		'echo."%_ENC_RAW%"^| call "%~dp0readline.bat"'
	) do set "_ENC_OUT=%%~b"
	endlocal & set "%~2=%_ENC_OUT%"
exit /b 0

:MAIN_RegisterBuiltins Env
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Env=%~1"
		set "%%.I=0"
		%{g% "!%%.Env!" RawKeys %%.RawKeys %}%

		%{% TYPES NewBatFn MAIN MAdd True %}% %->% %%.Fn
		%{% MAIN EncKey + %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" + %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MSub True %}% %->% %%.Fn
		%{% MAIN EncKey - %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" - %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MMul True %}% %->% %%.Fn
		%{% MAIN EncKey * %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" * %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MDiv True %}% %->% %%.Fn
		%{% MAIN EncKey / %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" / %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MEqual True %}% %->% %%.Fn
		%{% MAIN EncKey "=" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "=" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MLess True %}% %->% %%.Fn
		%{% MAIN EncKey "<" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		set "T2V=<"
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" !T2V! %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MGreat True %}% %->% %%.Fn
		%{% MAIN EncKey ">" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		set "T2V=>"
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" !T2V! %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MLE True %}% %->% %%.Fn
		%{% MAIN EncKey "<=" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		set "T2V=<="
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" !T2V! %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MGE True %}% %->% %%.Fn
		%{% MAIN EncKey ">=" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		set "T2V=>="
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" !T2V! %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MList True %}% %->% %%.Fn
		%{% MAIN EncKey list %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" list %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MListQ True %}% %->% %%.Fn
		%{% MAIN EncKey "list?" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "list?" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MEmptyQ True %}% %->% %%.Fn
		%{% MAIN EncKey "empty?" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "empty?" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MCount True %}% %->% %%.Fn
		%{% MAIN EncKey count %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" count %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MPrn True %}% %->% %%.Fn
		%{% MAIN EncKey prn %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" prn %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MNot True %}% %->% %%.Fn
		%{% MAIN EncKey not %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" not %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MPrStr True %}% %->% %%.Fn
		%{% MAIN EncKey "pr-str" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "pr-str" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MStr True %}% %->% %%.Fn
		%{% MAIN EncKey str %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" str %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MPrintln True %}% %->% %%.Fn
		%{% MAIN EncKey println %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" println %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MDef False %}% %->% %%.Fn
		%{% MAIN EncKey "def$E" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "def!" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MLet False %}% %->% %%.Fn
		%{% MAIN EncKey "let*" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "let*" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MFn False %}% %->% %%.Fn
		%{% MAIN EncKey "fn*" %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" "fn*" %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MIf False %}% %->% %%.Fn
		%{% MAIN EncKey if %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" if %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{% TYPES NewBatFn MAIN MDo False %}% %->% %%.Fn
		%{% MAIN EncKey do %}% %->% %%.Enc
		set /a %%.I += 1
		%{s% "!%%.Env!" "Item[!%%.Enc!].Count" 1 %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Key" do %}%
		%{s% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" "!%%.Fn!" %}%
		%{s% "!%%.RawKeys!" "Key[!%%.I!]" "!%%.Enc!" %}%

		%{s% "!%%.Env!" RawKeyCount "!%%.I!" %}%
	)
%-|%

:MAIN_Read Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% READER ReadString "!%%.Str!" %}% %->% %%.Mal
		%?% (
			%-|%
		)
		%<-% %%.Mal
	)
%-|%

:MAIN_Eval ObjMal Env -> ObjMal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.ObjMal=%~1"
		set "%%.Env=%~2"
		%{g% "!%%.ObjMal!" Type %%.Type %}%

		set "%%.EnvBody=!%%.Env!"
		if defined !%%.Env!.Target %&% "!%%.Env!.Target" "%%.EnvBody"

		set "%%.DbgOn=0"
		set "%%.DbgLookupEnv=!%%.Env!"
		set "%%.DbgFound=0"
		for /l %%l in (1 1 100) do if "!%%.DbgFound!" == "0" (
			%{% NSUTIL HasField "!%%.DbgLookupEnv!" "Item[!_G.DEBUGKEY!].Count" %}% %->% %%.DbgHas
			if "!%%.DbgHas!" == "1" (
				%{g% "!%%.DbgLookupEnv!" "Item[!_G.DEBUGKEY!].Item[1].Value" %%.DbgVal %}%
				set "%%.DbgFound=1"
			) else (
				%{g% "!%%.DbgLookupEnv!" Outer %%.DbgNextEnv %}%
				if "!%%.DbgNextEnv!" == "" (
					set "%%.DbgFound=2"
				) else (
					set "%%.DbgLookupEnv=!%%.DbgNextEnv!"
				)
			)
		)
		if "!%%.DbgFound!" == "1" (
			%{g% "!%%.DbgVal!" Type %%.DbgTy %}%
			if "!%%.DbgTy!" == "MalNil" (
				set "%%.DbgOn=0"
			) else if "!%%.DbgTy!" == "MalBool" (
				%{g% "!%%.DbgVal!" Value %%.DbgBv %}%
				if "!%%.DbgBv!" == "false" (
					set "%%.DbgOn=0"
				) else (
					set "%%.DbgOn=1"
				)
			) else (
				set "%%.DbgOn=1"
			)
		)
		if "!%%.DbgOn!" == "1" (
			%{% PRINTER PrintMalType "!%%.ObjMal!" R %}% %->% %%.DbgStr
			%{% STR GetStr %%.DbgStr %}% %->% %%.DbgRead
			set "%%.DbgLine=EVAL: !%%.DbgRead!"
			%{% IO WriteEncLine %%.DbgLine %}%
		)

		if "!%%.Type!" == "MalSym" (
			%{g% "!%%.ObjMal!" Value %%.Val %}%
			%{% MAIN EncKey "!%%.Val!" %}% %->% %%.Enc
			set "%%.SymLookupEnv=!%%.Env!"
			set "%%.SymFound=0"
			for /l %%l in (1 1 100) do if "!%%.SymFound!" == "0" (
				%{% NSUTIL HasField "!%%.SymLookupEnv!" "Item[!%%.Enc!].Count" %}% %->% %%.SymHasCnt
				if "!%%.SymHasCnt!" == "1" (
					%{g% "!%%.SymLookupEnv!" "Item[!%%.Enc!].Item[1].Value" %%.RetMal %}%
					set "%%.SymFound=1"
				) else (
					%{g% "!%%.SymLookupEnv!" Outer %%.SymNextEnv %}%
					if "!%%.SymNextEnv!" == "" (
						set "%%.SymFound=2"
					) else (
						set "%%.SymLookupEnv=!%%.SymNextEnv!"
					)
				)
			)
			if "!%%.SymFound!" == "2" (
				%??% "Symbol '!%%.Val!' not found."
				%-|%
			)
		) else if "!%%.Type!" == "MalLst" (
			%{g% "!%%.ObjMal!" Count %%.Count %}%
			if !%%.Count! gtr 0 (
				%{g% "!%%.ObjMal!" Item[1] %%.Item %}%
				%{% MAIN Eval "!%%.Item!" "!%%.Env!" %}% %->% %%.Fn
				%?% (
					%-|%
				)
				%{g% "!%%.Fn!" Type %%.FnType %}%
		if "!%%.FnType!" == "MalFn" (
			%{g% "!%%.Fn!" SubType %%.SubType %}%
			if "!%%.SubType!" == "MAL" (
				%{% TYPES NewMalList "!%%.Fn!" %}% %->% %%.Args
				set "%%.AI=1"
				for /l %%i in (2 1 !%%.Count!) do (
					%{g% "!%%.ObjMal!" Item[%%i] %%.Item %}%
					%{% MAIN Eval "!%%.Item!" "!%%.Env!" %}% %->% %%.NewItem
					%?% (
						%-|%
					)
					set /a %%.AI += 1
					%{s% "!%%.Args!" Item[!%%.AI!] "!%%.NewItem!" %}%
				)
				%{s% "!%%.Args!" Count "!%%.AI!" %}%
				%{% MAIN ApplyClosure "!%%.Fn!" "!%%.Args!" %}% %->% %%.RetMal
				%?% (
					%-|%
				)
			) else (
				%{g% "!%%.Fn!" AutoEval %%.AutoEval %}%
				if "!%%.AutoEval!" == "True" (
					%{% TYPES NewMalList "!%%.Fn!" %}% %->% %%.Args
					set "%%.AI=1"
					for /l %%i in (2 1 !%%.Count!) do (
						%{g% "!%%.ObjMal!" Item[%%i] %%.Item %}%
						%{% MAIN Eval "!%%.Item!" "!%%.Env!" %}% %->% %%.NewItem
						%?% (
							%-|%
						)
						set /a %%.AI += 1
						%{s% "!%%.Args!" Item[!%%.AI!] "!%%.NewItem!" %}%
					)
					%{s% "!%%.Args!" Count "!%%.AI!" %}%
				) else (
					set "%%.Args=!%%.ObjMal!"
				)
				%{g% "!%%.Fn!" Mod %%.Mod %}%
				%{g% "!%%.Fn!" Name %%.Name %}%
				call :!%%.Mod!_!%%.Name! "!%%.Args!" "!%%.Env!" %->% %%.RetMal
				%?% (
					%-|%
				)
			)
		) else (
			%??% "Can not invoke '!%%.FnType!'."
			%-|%
		)
			) else (
				rem empty list, return as-is.
				set "%%.RetMal=!%%.ObjMal!"
			)
		) else if "!%%.Type!" == "MalVec" (
			%{g% "!%%.ObjMal!" Count %%.Count %}%
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "!%%.ObjMal!" Item[%%i] %%.Item %}%
				%{% MAIN Eval "!%%.Item!" "!%%.Env!" %}% %->% %%.NewItem
				%?% (
					%-|%
				)
				%{s% "!%%.ObjMal!" Item[%%i] "!%%.NewItem!" %}%
			)
			set "%%.RetMal=!%%.ObjMal!"
		) else if "!%%.Type!" == "MalMap" (
			%{g% "!%%.ObjMal!" RawKeyCount %%.KeyCount %}%
			%{g% "!%%.ObjMal!" RawKeys %%.Keys %}%
			for /l %%i in (1 1 !%%.KeyCount!) do (
				%{g% "!%%.Keys!" Key[%%i] %%.RawKey %}%
				%{g% "!%%.ObjMal!" Item[!%%.RawKey!].Count %%.SameKeyCount %}%
				for /l %%j in (1 1 !%%.SameKeyCount!) do (
					%{g% "!%%.ObjMal!" Item[!%%.RawKey!].Item[%%j].Value %%.ValMal %}%
					%{% MAIN Eval "!%%.ValMal!" "!%%.Env!" %}% %->% %%.NewVal
					%?% (
						%-|%
					)
					%{s% "!%%.ObjMal!" Item[!%%.RawKey!].Item[%%j].Value "!%%.NewVal!" %}%
				)
			)
			set "%%.RetMal=!%%.ObjMal!"
		) else (
			set "%%.RetMal=!%%.ObjMal!"
		)

		%<-% %%.RetMal
	)
%-|%

:MAIN_Print Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{% PRINTER PrintMalType "!%%.Mal!" R %}% %->% %%.StrMal
		%?% (
			%-|%
		)
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		%?% (
			%-|%
		)
		%{% IO WriteEncLine %%.Result %}%
		%<-% %%.Result
	)
%-|%

:MAIN_REP Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% MAIN Read "%%.Str" %}% %->% %%.Mal
		%?% (
			%-|%
		)
		%{% MAIN Eval "!%%.Mal!" "!_G.ENV!" %}% %->% %%.Mal2
		%?% (
			%-|%
		)
		%{% MAIN Print "!%%.Mal2!" %}%
	)
%-|%

:MAIN_MAdd Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.MalNum1 %}%
		%{g% "!%%.Mal!" Item[3] %%.MalNum2 %}%
		%{% TYPES CheckType "!%%.MalNum1!" MalNum %}% %->% %%.IsNum1
		%{% TYPES CheckType "!%%.MalNum2!" MalNum %}% %->% %%.IsNum2
		if "!%%.IsNum1!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum1!" == "0" %-|%
		if "!%%.IsNum2!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum2!" == "0" %-|%
		%{g% "!%%.MalNum1!" Value %%.Num1 %}%
		%{g% "!%%.MalNum2!" Value %%.Num2 %}%
		set /a %%.Num = %%.Num1 + %%.Num2
		%{% TYPES NewMal MalNum "!%%.Num!" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MSub Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.MalNum1 %}%
		%{g% "!%%.Mal!" Item[3] %%.MalNum2 %}%
		%{% TYPES CheckType "!%%.MalNum1!" MalNum %}% %->% %%.IsNum1
		%{% TYPES CheckType "!%%.MalNum2!" MalNum %}% %->% %%.IsNum2
		if "!%%.IsNum1!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum1!" == "0" %-|%
		if "!%%.IsNum2!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum2!" == "0" %-|%
		%{g% "!%%.MalNum1!" Value %%.Num1 %}%
		%{g% "!%%.MalNum2!" Value %%.Num2 %}%
		set /a %%.Num = %%.Num1 - %%.Num2
		%{% TYPES NewMal MalNum "!%%.Num!" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MMul Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.MalNum1 %}%
		%{g% "!%%.Mal!" Item[3] %%.MalNum2 %}%
		%{% TYPES CheckType "!%%.MalNum1!" MalNum %}% %->% %%.IsNum1
		%{% TYPES CheckType "!%%.MalNum2!" MalNum %}% %->% %%.IsNum2
		if "!%%.IsNum1!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum1!" == "0" %-|%
		if "!%%.IsNum2!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum2!" == "0" %-|%
		%{g% "!%%.MalNum1!" Value %%.Num1 %}%
		%{g% "!%%.MalNum2!" Value %%.Num2 %}%
		set /a %%.Num = %%.Num1 * %%.Num2
		%{% TYPES NewMal MalNum "!%%.Num!" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MDiv Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.MalNum1 %}%
		%{g% "!%%.Mal!" Item[3] %%.MalNum2 %}%
		%{% TYPES CheckType "!%%.MalNum1!" MalNum %}% %->% %%.IsNum1
		%{% TYPES CheckType "!%%.MalNum2!" MalNum %}% %->% %%.IsNum2
		if "!%%.IsNum1!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum1!" == "0" %-|%
		if "!%%.IsNum2!" == "0" %??% "Invalid argument type."
		if "!%%.IsNum2!" == "0" %-|%
		%{g% "!%%.MalNum1!" Value %%.Num1 %}%
		%{g% "!%%.MalNum2!" Value %%.Num2 %}%
		set /a %%.Num = %%.Num1 / %%.Num2
		%{% TYPES NewMal MalNum "!%%.Num!" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_Truthy ValMal -> TrueFalse
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.V=%~1"
		set "%%.TF=1"
		%{g% "!%%.V!" Type %%.T %}%
		if "!%%.T!" == "MalNil" (
			set "%%.TF=0"
		) else if "!%%.T!" == "MalBool" (
			%{g% "!%%.V!" Value %%.Bv %}%
			if "!%%.Bv!" == "false" set "%%.TF=0"
		)
		%<-% %%.TF
	)
%-|%

:MAIN_ApplyClosure FnMal ObjMal -> RetMal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Fn=%~1"
		set "%%.Obj=%~2"
		%{g% "!%%.Fn!" Env %%.CapEnv %}%
		%{g% "!%%.Fn!" Binds %%.Binds %}%
		%{g% "!%%.Fn!" Body %%.Body %}%
		%{g% "!%%.Obj!" Count %%.ArgN %}%
		%{g% "!%%.Binds!" Count %%.BindN %}%
		%{% TYPES NewMalMap %}% %->% %%.NewEnv
		%{s% "!%%.NewEnv!" Outer "!%%.CapEnv!" %}%
		rem Scan for variadic marker '&' (MalSym Value == '&')
		set "%%.Amp="
		for /l %%b in (1 1 !%%.BindN!) do (
			%{g% "!%%.Binds!" Item[%%b] %%.ParamB %}%
			%{g% "!%%.ParamB!" Type %%.ParamBType %}%
			if "!%%.ParamBType!" == "MalSym" (
				%{g% "!%%.ParamB!" Value %%.ParamBVal %}%
				if "!%%.ParamBVal!" == "&" set "%%.Amp=%%b"
			)
		)
		if defined %%.Amp (
			if !%%.Amp! geq !%%.BindN! (
				%??% "The parameter name after & is missing."
				%-|%
			)
			set /a %%.Amp2 = %%.Amp + 1
			%{g% "!%%.Binds!" Item[!%%.Amp2!] %%.RestParam %}%
			%{% TYPES CheckType "!%%.RestParam!" MalSym %}% %->% %%.RestIsSym
			if "!%%.RestIsSym!" == "0" (
				%??% "& must be followed by a symbol."
				%-|%
			)
		) else (
			set /a %%.Need = %%.ArgN - 1
			if !%%.BindN! neq !%%.Need! (
				%??% "Invalid number of arguments."
				%-|%
			)
		)
		if defined %%.Amp (
			set /a %%.FixedN = %%.Amp - 1
		) else (
			set "%%.FixedN=!%%.BindN!"
		)
		if !%%.FixedN! gtr 0 (
			for /l %%b in (1 1 !%%.FixedN!) do (
				set /a %%.ArgIdx = %%b + 1
				%{g% "!%%.Binds!" Item[%%b] %%.Param %}%
				%{g% "!%%.Param!" Value %%.PName %}%
				%{% MAIN EncKey "!%%.PName!" %}% %->% %%.PEnc
				%{g% "!%%.Obj!" Item[!%%.ArgIdx!] %%.ArgVal %}%
				call :MAIN_BindOne "!%%.NewEnv!" "!%%.PName!" "!%%.PEnc!" "!%%.ArgVal!"
				%?% (
					%-|%
				)
			)
		)
		if defined %%.Amp (
			set /a %%.RestIdx = %%.Amp + 1
			%{g% "!%%.Binds!" Item[!%%.RestIdx!] %%.RestParam2 %}%
			%{g% "!%%.RestParam2!" Value %%.RestName %}%
			%{% MAIN EncKey "!%%.RestName!" %}% %->% %%.RestEnc
			%{% TYPES NewMalList %}% %->% %%.RestList
			set "%%.RI=0"
			set /a %%.RestStart = %%.Amp + 1
			if !%%.ArgN! geq !%%.RestStart! (
				for /l %%i in (!%%.RestStart! 1 !%%.ArgN!) do (
					%{g% "!%%.Obj!" Item[%%i] %%.ArgValR %}%
					set /a %%.RI += 1
					%{s% "!%%.RestList!" Item[!%%.RI!] "!%%.ArgValR!" %}%
				)
			)
			%{s% "!%%.RestList!" Count "!%%.RI!" %}
			call :MAIN_BindOne "!%%.NewEnv!" "!%%.RestName!" "!%%.RestEnc!" "!%%.RestList!"
			%?% (
				%-|%
			)
		)
		%{% TYPES NewMal MalNil nil %}% %->% %%.RetMal
		%{g% "!%%.Body!" Count %%.BodyN %}%
		for /l %%z in (1 1 !%%.BodyN!) do (
			%{g% "!%%.Body!" Item[%%z] %%.Form %}%
			%{% MAIN Eval "!%%.Form!" "!%%.NewEnv!" %}% %->% %%.NewForm
			%?% (
				%-|%
			)
			set "%%.RetMal=!%%.NewForm!"
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_BindOne NewEnv Name Enc Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{s% "%~1" "Item[%~3].Count" 1 %}%
		%{s% "%~1" "Item[%~3].Item[1].Key" "%~2" %}%
		%{s% "%~1" "Item[%~3].Item[1].Value" "%~4" %}%
		%{g% "%~1" RawKeys %%.RK %}%
		%{g% "%~1" RawKeyCount %%.RC %}%
		if "!%%.RC!" == "" set "%%.RC=0"
		set /a %%.RC += 1
		%{s% "!%%.RK!" Key[!%%.RC!] "%~3" %}%
		%{s% "%~1" RawKeyCount "!%%.RC!" %}%
	)
%-|%

:MAIN_MFn Mal Env -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		set "%%.Env=%~2"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! lss 2 (
			%??% "fn* expects (fn* (binds) body...)."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.Binds %}%
		%{% TYPES CheckType "!%%.Binds!" MalLst MalVec %}% %->% %%.IsL
		if "!%%.IsL!" == "0" (
			%??% "fn* binds should be a list/vector."
			%-|%
		)
		%{% TYPES NewMalList %}% %->% %%.Body
		set "%%.BN=0"
		for /l %%i in (3 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.Form %}%
			set /a %%.BN += 1
			%{s% "!%%.Body!" Item[!%%.BN!] "!%%.Form!" %}%
		)
		%{s% "!%%.Body!" Count "!%%.BN!" %}%
		%{% TYPES NewMalFn "!%%.Binds!" "!%%.Body!" "!%%.Env!" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MIf Mal Env -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		set "%%.Env=%~2"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! lss 3 (
			%??% "if expects (if cond then [else])."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.Cond %}%
		%{% MAIN Eval "!%%.Cond!" "!%%.Env!" %}% %->% %%.CondVal
		%?% (
			%-|%
		)
		%{% MAIN Truthy "!%%.CondVal!" %}% %->% %%.TF
		if "!%%.TF!" == "1" (
			%{g% "!%%.Mal!" Item[3] %%.Then %}%
			%{% MAIN Eval "!%%.Then!" "!%%.Env!" %}% %->% %%.RetMal
			%?% (
				%-|%
			)
		) else (
			if !%%.Count! gtr 3 (
				%{g% "!%%.Mal!" Item[4] %%.Else %}%
				%{% MAIN Eval "!%%.Else!" "!%%.Env!" %}% %->% %%.RetMal
				%?% (
					%-|%
				)
			) else (
				%{% TYPES NewMal MalNil nil %}% %->% %%.RetMal
			)
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_MDo Mal Env -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		set "%%.Env=%~2"
		%{g% "!%%.Mal!" Count %%.Count %}%
		%{% TYPES NewMal MalNil nil %}% %->% %%.RetMal
		for /l %%i in (2 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.Form %}%
			%{% MAIN Eval "!%%.Form!" "!%%.Env!" %}% %->% %%.NewForm
			%?% (
				%-|%
			)
			set "%%.RetMal=!%%.NewForm!"
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_MList Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		%{% TYPES NewMalList %}% %->% %%.RetMal
		set "%%.LI=0"
		for /l %%i in (2 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.It %}%
			set /a %%.LI += 1
			%{s% "!%%.RetMal!" Item[!%%.LI!] "!%%.It!" %}%
		)
		%{s% "!%%.RetMal!" Count "!%%.LI!" %}%
		%<-% %%.RetMal
	)
%-|%

:MAIN_MListQ Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 2 (
			%??% "list? expects 1 argument."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.X %}%
		%{g% "!%%.X!" Type %%.XT %}%
		%{% TYPES NewMal MalBool true %}% %->% %%.RetMal
		if "!%%.XT!" neq "MalLst" (
			%{% TYPES NewMal MalBool false %}% %->% %%.RetMal
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_MEmptyQ Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 2 (
			%??% "empty? expects 1 argument."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.X %}%
		%{g% "!%%.X!" Type %%.XT %}%
		%{% TYPES NewMal MalBool false %}% %->% %%.RetMal
		if "!%%.XT!" == "MalLst" (
			%{g% "!%%.X!" Count %%.XC %}%
			if !%%.XC! equ 0 (
				%{% TYPES NewMal MalBool true %}% %->% %%.RetMal
			)
		) else if "!%%.XT!" == "MalVec" (
			%{g% "!%%.X!" Count %%.XC %}%
			if !%%.XC! equ 0 (
				%{% TYPES NewMal MalBool true %}% %->% %%.RetMal
			)
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_MCount Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 2 (
			%??% "count expects 1 argument."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.X %}%
		%{g% "!%%.X!" Type %%.XT %}%
		set "%%.NN=0"
		if "!%%.XT!" == "MalLst" (
			%{g% "!%%.X!" Count %%.NN %}%
		) else if "!%%.XT!" == "MalVec" (
			%{g% "!%%.X!" Count %%.NN %}%
		)
		%{% TYPES NewMal MalNum "!%%.NN!" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_SameMal A B -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.A=%~1"
		set "%%.B=%~2"
		set "%%.Eq=1"
		%{g% "!%%.A!" Type %%.AT %}%
		%{g% "!%%.B!" Type %%.BT %}%
		if "!%%.AT!" neq "!%%.BT!" (
			set "%%.SeqA=0"
			if "!%%.AT!" == "MalLst" set "%%.SeqA=1"
			if "!%%.AT!" == "MalVec" set "%%.SeqA=1"
			set "%%.SeqB=0"
			if "!%%.BT!" == "MalLst" set "%%.SeqB=1"
			if "!%%.BT!" == "MalVec" set "%%.SeqB=1"
			if "!%%.SeqA!" == "1" (
				if "!%%.SeqB!" == "1" (
					%{g% "!%%.A!" Count %%.AC %}%
					%{g% "!%%.B!" Count %%.BC %}%
					if !%%.AC! neq !%%.BC! (
						set "%%.Eq=0"
					) else (
						set "%%.Eq=1"
						for /l %%i in (1 1 !%%.AC!) do (
							%{g% "!%%.A!" Item[%%i] %%.Ai %}%
							%{g% "!%%.B!" Item[%%i] %%.Bi %}%
							%{% MAIN SameMal "!%%.Ai!" "!%%.Bi!" %}% %->% %%.Sub
							if "!%%.Sub!" == "0" set "%%.Eq=0"
						)
					)
				) else (
					set "%%.Eq=0"
				)
			) else (
				set "%%.Eq=0"
			)
		) else if "!%%.AT!" == "MalNil" (
			set "%%.Eq=1"
		) else if "!%%.AT!" == "MalLst" (
			%{g% "!%%.A!" Count %%.AC %}%
			%{g% "!%%.B!" Count %%.BC %}%
			if !%%.AC! neq !%%.BC! (
				set "%%.Eq=0"
			)
			if "!%%.Eq!" == "1" (
				for /l %%i in (1 1 !%%.AC!) do (
					%{g% "!%%.A!" Item[%%i] %%.Ai %}%
					%{g% "!%%.B!" Item[%%i] %%.Bi %}%
					%{% MAIN SameMal "!%%.Ai!" "!%%.Bi!" %}% %->% %%.Sub
					if "!%%.Sub!" == "0" set "%%.Eq=0"
				)
			)
		) else if "!%%.AT!" == "MalVec" (
			%{g% "!%%.A!" Count %%.AC %}%
			%{g% "!%%.B!" Count %%.BC %}%
			if !%%.AC! neq !%%.BC! (
				set "%%.Eq=0"
			)
			if "!%%.Eq!" == "1" (
				for /l %%i in (1 1 !%%.AC!) do (
					%{g% "!%%.A!" Item[%%i] %%.Ai %}%
					%{g% "!%%.B!" Item[%%i] %%.Bi %}%
					%{% MAIN SameMal "!%%.Ai!" "!%%.Bi!" %}% %->% %%.Sub
					if "!%%.Sub!" == "0" set "%%.Eq=0"
				)
			)
		) else if "!%%.AT!" == "MalMap" (
			%{g% "!%%.A!" RawKeyCount %%.AC %}%
			%{g% "!%%.B!" RawKeyCount %%.BC %}%
			if !%%.AC! neq !%%.BC! (
				set "%%.Eq=0"
			)
			if "!%%.Eq!" == "1" (
				%{g% "!%%.A!" RawKeys %%.AK %}%
				for /l %%i in (1 1 !%%.AC!) do (
					%{g% "!%%.AK!" Key[%%i] %%.Rk %}%
					%{g% "!%%.A!" "Item[!%%.Rk!].Count" %%.ACnt %}%
					%{g% "!%%.B!" "Item[!%%.Rk!].Count" %%.BCnt %}%
					if "!%%.ACnt!" neq "!%%.BCnt!" (
						set "%%.Eq=0"
					)
					if "!%%.Eq!" == "1" (
						for /l %%j in (1 1 !%%.ACnt!) do (
							%{g% "!%%.A!" "Item[!%%.Rk!].Item[%%j].Key" %%.Ak %}%
							%{g% "!%%.A!" "Item[!%%.Rk!].Item[%%j].Value" %%.Av %}%
							%{g% "!%%.B!" "Item[!%%.Rk!].Item[%%j].Key" %%.Bk %}%
							%{g% "!%%.B!" "Item[!%%.Rk!].Item[%%j].Value" %%.Bv %}%
							%{% MAIN SameMal "!%%.Ak!" "!%%.Bk!" %}% %->% %%.Sub
							if "!%%.Sub!" == "0" set "%%.Eq=0"
							%{% MAIN SameMal "!%%.Av!" "!%%.Bv!" %}% %->% %%.Sub
							if "!%%.Sub!" == "0" set "%%.Eq=0"
						)
					)
				)
			)
		) else (
			%{g% "!%%.A!" Value %%.AV %}%
			%{g% "!%%.B!" Value %%.BV %}%
			if "!%%.AV!" neq "!%%.BV!" set "%%.Eq=0"
		)
		%<-% %%.Eq
	)
%-|%

:MAIN_MEqual Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "= expects 2 arguments."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.A %}%
		%{g% "!%%.Mal!" Item[3] %%.B %}%
		%{% MAIN SameMal "!%%.A!" "!%%.B!" %}% %->% %%.Eq
		%{% TYPES NewMal MalBool true %}% %->% %%.RetMal
		if "!%%.Eq!" == "0" (
			%{% TYPES NewMal MalBool false %}% %->% %%.RetMal
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_CmpNum Mal CmpOp -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "compare expects 2 arguments."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.A %}%
		%{g% "!%%.Mal!" Item[3] %%.B %}%
		%{% TYPES CheckType "!%%.A!" MalNum %}% %->% %%.IsA
		%{% TYPES CheckType "!%%.B!" MalNum %}% %->% %%.IsB
		if "!%%.IsA!" == "0" %??% "Invalid argument type."
		if "!%%.IsA!" == "0" %-|%
		if "!%%.IsB!" == "0" %??% "Invalid argument type."
		if "!%%.IsB!" == "0" %-|%
		%{g% "!%%.A!" Value %%.AV %}%
		%{g% "!%%.B!" Value %%.BV %}%
		set "%%.T=0"
		if "%~2" == "lss" if !%%.AV! lss !%%.BV! set "%%.T=1"
		if "%~2" == "gtr" if !%%.AV! gtr !%%.BV! set "%%.T=1"
		if "%~2" == "leq" if !%%.AV! leq !%%.BV! set "%%.T=1"
		if "%~2" == "geq" if !%%.AV! geq !%%.BV! set "%%.T=1"
		%{% TYPES NewMal MalBool true %}% %->% %%.RetMal
		if "!%%.T!" == "0" (
			%{% TYPES NewMal MalBool false %}% %->% %%.RetMal
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_MLess Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{% MAIN CmpNum "!%%.Mal!" lss %}% %->% %%.RetMal
		%?% ( %-|% )
		%<-% %%.RetMal
	)
%-|%

:MAIN_MGreat Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{% MAIN CmpNum "!%%.Mal!" gtr %}% %->% %%.RetMal
		%?% ( %-|% )
		%<-% %%.RetMal
	)
%-|%

:MAIN_MLE Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{% MAIN CmpNum "!%%.Mal!" leq %}% %->% %%.RetMal
		%?% ( %-|% )
		%<-% %%.RetMal
	)
%-|%

:MAIN_MGE Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{% MAIN CmpNum "!%%.Mal!" geq %}% %->% %%.RetMal
		%?% ( %-|% )
		%<-% %%.RetMal
	)
%-|%

:MAIN_MPrn Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		set "%%.Out="
		for /l %%i in (2 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.It %}%
			%{% PRINTER PrintMalType "!%%.It!" R %}% %->% %%.Str
			%{% STR GetStr %%.Str %}% %->% %%.Read
			if defined %%.Out (
				set "%%.Out=!%%.Out! !%%.Read!"
			) else (
				set "%%.Out=!%%.Read!"
			)
		)
		set "%%.Line=!%%.Out!"
		%{% IO WriteEncLine %%.Line %}%
		%{% TYPES NewMal MalNil nil %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MNot Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 2 (
			%??% "not expects 1 argument."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.X %}%
		%{% MAIN Truthy "!%%.X!" %}% %->% %%.TF
		%{% TYPES NewMal MalBool false %}% %->% %%.RetMal
		if "!%%.TF!" == "0" (
			%{% TYPES NewMal MalBool true %}% %->% %%.RetMal
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_MPrStr Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		%{% STR New %}% %->% %%.Out
		for /l %%i in (2 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.It %}%
			%{% PRINTER PrintMalType "!%%.It!" R %}% %->% %%.Str
			if %%i gtr 2 (
				%{% STR AppendVal %%.Out " " %}
			)
			%{% STR AppendStr %%.Out %%.Str %}
		)
		%{% STR GetStr %%.Out %}% %->% %%.Joined
		%{% TYPES NewMal MalStr "$D!%%.Joined!$D" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MStr Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		%{% STR New %}% %->% %%.Out
		for /l %%i in (2 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.It %}%
			%{% PRINTER PrintMalType "!%%.It!" %}% %->% %%.Str
			%{% STR AppendStr %%.Out %%.Str %}
		)
		%{% STR GetStr %%.Out %}% %->% %%.Joined
		%{% TYPES NewMal MalStr "$D!%%.Joined!$D" %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MPrintln Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		%{g% "!%%.Mal!" Count %%.Count %}%
		set "%%.Out="
		for /l %%i in (2 1 !%%.Count!) do (
			%{g% "!%%.Mal!" Item[%%i] %%.It %}%
			%{% PRINTER PrintMalType "!%%.It!" %}% %->% %%.Str
			%{% STR GetStr %%.Str %}% %->% %%.Read
			if defined %%.Out (
				set "%%.Out=!%%.Out! !%%.Read!"
			) else (
				set "%%.Out=!%%.Read!"
			)
		)
		%{% IO WriteEncLine %%.Out %}%
		%{% TYPES NewMal MalNil nil %}% %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_EncKey Val -> Enc
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Enc="
		set "%%.S=%~1"
	)
	:MAIN_EncKey_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if defined %%.S (
			set "%%.Ch=!%%.S:~,1!"
			set "%%.S=!%%.S:~1!"
			set "%%.IsLo=0"
			for %%l in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
				if "!%%.Ch!" == "%%l" set "%%.IsLo=1"
			)
			if "!%%.IsLo!" == "1" (
				set "%%.Enc=!%%.Enc!!%%.Ch!0"
				goto MAIN_EncKey_Loop
			)
			if "!%%.Ch!" equ "!" (
				set "%%.Enc=!%%.Enc!$E"
				goto MAIN_EncKey_Loop
			)
			for %%c in ("<" ">" "=") do (
				if "!%%.Ch!" == "%%~c" (
					if "%%~c" == "<" (
						set "%%.Enc=!%%.Enc!LT"
					) else if "%%~c" == ">" (
						set "%%.Enc=!%%.Enc!GT"
					) else (
						set "%%.Enc=!%%.Enc!EQ"
					)
					goto MAIN_EncKey_Loop
				)
			)
			set "%%.Enc=!%%.Enc!!%%.Ch!1"
			goto MAIN_EncKey_Loop
		)
		%<-% %%.Enc
	)
%-|%

:MAIN_MDef Mal Env -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		set "%%.Env=%~2"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.Sym %}%
		%{% TYPES CheckType "!%%.Sym!" MalSym %}% %->% %%.IsSym
		if "!%%.IsSym!" == "0" %??% "Invalid argument type."
		if "!%%.IsSym!" == "0" %-|%
		%{g% "!%%.Sym!" Value %%.Key %}%
		%{% MAIN EncKey "!%%.Key!" %}% %->% %%.Enc
		%{g% "!%%.Mal!" Item[3] %%.Val %}%
		%{% MAIN Eval "!%%.Val!" "!%%.Env!" %}% %->% %%.NewVal
		%?% (
			%-|%
		)
		%{d% "!%%.Env!" Item[!%%.Enc!].Count 1 %}%
		%{d% "!%%.Env!" Item[!%%.Enc!].Item[1].Key "!%%.Key!" %}%
		%{d% "!%%.Env!" Item[!%%.Enc!].Item[1].Value "!%%.NewVal!" %}%
		%{g% "!%%.Env!" RawKeyCount %%.RKC %}%
		if "!%%.RKC!" == "" set "%%.RKC=0"
		set /a %%.RKC += 1
		%{g% "!%%.Env!" RawKeys %%.RawKeys %}%
		%{d% "!%%.RawKeys!" Key[!%%.RKC!] "!%%.Enc!" %}%
		%{d% "!%%.Env!" RawKeyCount !%%.RKC! %}%
		%<-% %%.NewVal
	)
%-|%

:MAIN_MLet Mal Env -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=%~1"
		set "%%.Env=%~2"
		%{g% "!%%.Mal!" Count %%.Count %}%
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%{g% "!%%.Mal!" Item[2] %%.BindList %}%
		%{% TYPES CheckType "!%%.BindList!" MalLst MalVec %}% %->% %%.IsList
		if "!%%.IsList!" == "0" %??% "Invalid argument type."
		if "!%%.IsList!" == "0" %-|%
		%{g% "!%%.BindList!" Count %%.BindCount %}%
		set /a "%%.IsOdd = %%.BindCount & 1"
		if !%%.IsOdd! equ 1 (
			%??% "The binding list is not valid and should have an even number of elements."
			%-|%
		)
		%{% TYPES NewMalMap %}% %->% %%.NewEnv
		%{s% "!%%.NewEnv!" Outer "!%%.Env!" %}%
		for /l %%i in (1 2 !%%.BindCount!) do (
			set /a %%.KeyIndex = %%i
			set /a %%.ValIndex = %%i + 1
			%{g% "!%%.BindList!" Item[!%%.KeyIndex!] %%.Key %}%
			%{g% "!%%.BindList!" Item[!%%.ValIndex!] %%.Val %}%
			%{% TYPES CheckType "!%%.Key!" MalSym %}% %->% %%.IsSym
			if "!%%.IsSym!" == "0" %??% "Invalid binding list key type, expect 'MalSym'."
			if "!%%.IsSym!" == "0" %-|%
			%{g% "!%%.Key!" Value %%.RawKey %}%
			%{% MAIN EncKey "!%%.RawKey!" %}% %->% %%.RepKey
			%{% MAIN Eval "!%%.Val!" "!%%.NewEnv!" %}% %->% %%.NewVal
			%?% (
				%-|%
			)
			%{d% "!%%.NewEnv!" Item[!%%.RepKey!].Count 1 %}%
			%{d% "!%%.NewEnv!" Item[!%%.RepKey!].Item[1].Key "!%%.RawKey!" %}%
			%{d% "!%%.NewEnv!" Item[!%%.RepKey!].Item[1].Value "!%%.NewVal!" %}%
			%{g% "!%%.NewEnv!" RawKeys %%.Keys %}%
			%{g% "!%%.NewEnv!" RawKeyCount %%.KC %}%
			if "!%%.KC!" == "" set "%%.KC=0"
			set /a %%.KC += 1
			%{s% "!%%.Keys!" Key[!%%.KC!] "!%%.RepKey!" %}%
			%{d% "!%%.NewEnv!" RawKeyCount !%%.KC! %}%
		)
		%{g% "!%%.Mal!" Item[3] %%.Body %}%
		%{% MAIN Eval "!%%.Body!" "!%%.NewEnv!" %}% %->% %%.RetMal
		%?% (
			%-|%
		)
		%<-% %%.RetMal
	)
%-|%

:MAIN_EnvCopyOuter Env NewEnv
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Env=%~1"
		set "%%.NewEnv=%~2"
		%{% TYPES NewMalMap %}% %->% %%.NewKeys
		%{g% "!%%.Env!" RawKeyCount %%.KeyCount %}%
		if "!%%.KeyCount!" == "" set "%%.KeyCount=0"
		%{g% "!%%.Env!" RawKeys %%.Keys %}%
		set "%%.Idx=0"
		for /l %%i in (1 1 !%%.KeyCount!) do (
			%{g% "!%%.Keys!" Key[%%i] %%.RawKey %}%
			if defined %%.RawKey (
				%{g% "!%%.Env!" "Item[!%%.RawKey!].Count" %%.SameCnt %}%
				if defined %%.SameCnt (
					for /l %%j in (1 1 !%%.SameCnt!) do (
						%{g% "!%%.Env!" "Item[!%%.RawKey!].Item[%%j].Key" %%.KeyMal %}%
						%{g% "!%%.Env!" "Item[!%%.RawKey!].Item[%%j].Value" %%.ValMal %}%
						%{s% "!%%.NewEnv!" "Item[!%%.RawKey!].Item[%%j].Key" "!%%.KeyMal!" %}%
						%{s% "!%%.NewEnv!" "Item[!%%.RawKey!].Item[%%j].Value" "!%%.ValMal!" %}%
					)
					%{s% "!%%.NewEnv!" "Item[!%%.RawKey!].Count" "!%%.SameCnt!" %}%
				)
				set /a %%.Idx += 1
				%{s% "!%%.NewKeys!" Key[!%%.Idx!] "!%%.RawKey!" %}%
			)
		)
		%{s% "!%%.NewEnv!" RawKeyCount "!%%.Idx!" %}%
		%{s% "!%%.NewEnv!" RawKeys "!%%.NewKeys!" %}%
	)
%-|%
:UTIL_SetRet

	if defined _G.NSUTIL (

		call set "_T.SR.Type=%%!%~1!.Type%%"

		if /i "!_T.SR.Type!" == "NSMeta" (

			if defined _G.LEVEL[!_G.LEVEL!][!%~1!] (

				set "_G.LEVEL[!_G.LEVEL!][!%~1!]="

				set /a "_T.SR.PrevLevel = _G.LEVEL - 1"

				set "_G.RET=!%~1!"

				set "_G.LEVEL[!_T.SR.PrevLevel!][!_G.RET!]=!_G.RET!"

			) else (

				set "_G.RET=!%~1!"

			)

		) else (

			set "_G.RET=!%~1!"

		)

	) else (

		set "_G.RET=!%~1!"

	)

exit /b 0



:UTIL_GetRet

	if not defined _G.ERR (

		set "%~1=!_G.RET!"

	)

	set "_G.RET="

exit /b 0

