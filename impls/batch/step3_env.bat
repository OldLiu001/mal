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
		call !_T.UTIL! :UTIL_Invoke MAIN REP _M.RDALL.Line
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

		%{% TYPES NewBatFn MAIN MAdd True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[+1].Count 1 %}%
		%{s% "!%%.Env!" Item[+1].Item[1].Key + %}%
		%{s% "!%%.Env!" Item[+1].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MSub True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[-1].Count 1 %}%
		%{s% "!%%.Env!" Item[-1].Item[1].Key - %}%
		%{s% "!%%.Env!" Item[-1].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MMul True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[*1].Count 1 %}%
		%{s% "!%%.Env!" Item[*1].Item[1].Key * %}%
		%{s% "!%%.Env!" Item[*1].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MDiv True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[/1].Count 1 %}%
		%{s% "!%%.Env!" Item[/1].Item[1].Key / %}%
		%{s% "!%%.Env!" Item[/1].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MDef False %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[d0e0f0$1E1].Count 1 %}%
		%{s% "!%%.Env!" Item[d0e0f0$1E1].Item[1].Key def$E %}%
		%{s% "!%%.Env!" Item[d0e0f0$1E1].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MLet False %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[l0e0t0*1].Count 1 %}%
		%{s% "!%%.Env!" Item[l0e0t0*1].Item[1].Key let* %}%
		%{s% "!%%.Env!" Item[l0e0t0*1].Item[1].Value !%%.Fn! %}%

		%{g% "!%%.Env!" RawKeys %%.RawKeys %}%
		%{s% "!%%.RawKeys!" Key[1] +1 %}%
		%{s% "!%%.RawKeys!" Key[2] -1 %}%
		%{s% "!%%.RawKeys!" Key[3] *1 %}%
		%{s% "!%%.RawKeys!" Key[4] /1 %}%
		%{s% "!%%.RawKeys!" Key[5] d0e0f0$1E1 %}%
		%{s% "!%%.RawKeys!" Key[6] l0e0t0*1 %}%
		%{s% "!%%.Env!" RawKeyCount 6 %}%
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
		%{% NSUTIL HasField "!%%.Env!" "Item[!_G.DEBUGKEY!].Count" %}% %->% %%.DbgHas
		if "!%%.DbgHas!" == "1" (
			%{g% "!%%.Env!" "Item[!_G.DEBUGKEY!].Item[1].Value" %%.DbgVal %}%
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
			%{% PRINTER PrintMalType "!%%.ObjMal!" %}% %->% %%.DbgStr
			%{% STR GetStr %%.DbgStr %}% %->% %%.DbgRead
			set "%%.DbgLine=EVAL: !%%.DbgRead!"
			%{% IO WriteEncLine %%.DbgLine %}%
		)

		if "!%%.Type!" == "MalSym" (
			%{g% "!%%.ObjMal!" Value %%.Val %}%
			%{% MAIN EncKey "!%%.Val!" %}% %->% %%.Enc
			%{% NSUTIL HasField "!%%.Env!" "Item[!%%.Enc!].Count" %}% %->% %%.HasCnt
			if "!%%.HasCnt!" == "1" (
				%{g% "!%%.Env!" "Item[!%%.Enc!].Item[1].Value" %%.RetMal %}%
			) else (
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
					%{g% "!%%.Fn!" AutoEval %%.AutoEval %}%
					if "!%%.AutoEval!" == "True" (
						for /l %%i in (2 1 !%%.Count!) do (
							%{g% "!%%.ObjMal!" Item[%%i] %%.Item %}%
							%{% MAIN Eval "!%%.Item!" "!%%.Env!" %}% %->% %%.NewItem
							%?% (
								%-|%
							)
							%{s% "!%%.ObjMal!" Item[%%i] "!%%.NewItem!" %}%
						)
					)
					%{g% "!%%.Fn!" Mod %%.Mod %}%
					%{g% "!%%.Fn!" Name %%.Name %}%
					call :!%%.Mod!_!%%.Name! "!%%.ObjMal!" "!%%.Env!" %->% %%.RetMal
					%?% (
						%-|%
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
		%{% PRINTER PrintMalType "!%%.Mal!" %}% %->% %%.StrMal
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
		%{s% "!%%.Env!" Item[!%%.Enc!].Count 1 %}%
		%{s% "!%%.Env!" Item[!%%.Enc!].Item[1].Key "!%%.Key!" %}%
		%{s% "!%%.Env!" Item[!%%.Enc!].Item[1].Value "!%%.NewVal!" %}%
		%{g% "!%%.Env!" RawKeyCount %%.RKC %}%
		if "!%%.RKC!" == "" set "%%.RKC=0"
		set /a %%.RKC += 1
		%{g% "!%%.Env!" RawKeys %%.RawKeys %}%
		%{s% "!%%.RawKeys!" Key[!%%.RKC!] "!%%.Enc!" %}%
		%{s% "!%%.Env!" RawKeyCount !%%.RKC! %}%
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
		%{% MAIN EnvCopyOuter "!%%.Env!" "!%%.NewEnv!" %}%
		%?% (
			%-|%
		)
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
			%{s% "!%%.NewEnv!" Item[!%%.RepKey!].Count 1 %}%
			%{s% "!%%.NewEnv!" Item[!%%.RepKey!].Item[1].Key "!%%.RawKey!" %}%
			%{s% "!%%.NewEnv!" Item[!%%.RepKey!].Item[1].Value "!%%.NewVal!" %}%
			%{g% "!%%.NewEnv!" RawKeys %%.Keys %}%
			%{g% "!%%.NewEnv!" RawKeyCount %%.KC %}%
			if "!%%.KC!" == "" set "%%.KC=0"
			set /a %%.KC += 1
			%{s% "!%%.Keys!" Key[!%%.KC!] "!%%.RepKey!" %}%
			%{s% "!%%.NewEnv!" RawKeyCount "!%%.KC!" %}%
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

