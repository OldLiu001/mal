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

%{% MAIN Main %}%
%-|%

:MAIN_Main
	if not defined _G.ENV (
		%{% TYPES NewMalMap %}% %->% _G.ENV
		%{% MAIN RegisterBuiltins _G.ENV %}%
	)
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
				( set _G.ERR ) > "%TEMP%\mal_e.txt" 2>nul
				for /f "usebackq delims==" %%a in ("%TEMP%\mal_e.txt") do set "%%a="
			)
		) else (
			exit /b 0
		)
	)
	goto MAIN_REPL_Loop
%-|%

:MAIN_RegisterBuiltins Env
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Env=%~1"

		%{% TYPES NewBatFn MAIN MAdd True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[+1].Count 1 %}%
		%{s% "!%%.Env!" Item[+1].Item[1].Key + %}%
		%{s% "!%%.Env!" Item[+].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MSub True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[-1].Count 1 %}%
		%{s% "!%%.Env!" Item[-1].Item[1].Key - %}%
		%{s% "!%%.Env!" Item[-].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MMul True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[*1].Count 1 %}%
		%{s% "!%%.Env!" Item[*1].Item[1].Key * %}%
		%{s% "!%%.Env!" Item[*].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MDiv True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[/1].Count 1 %}%
		%{s% "!%%.Env!" Item[/1].Item[1].Key / %}%
		%{s% "!%%.Env!" Item[/].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MDef False %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[d0e0f1$1E1].Count 1 %}%
		%{s% "!%%.Env!" Item[def$E].Item[1].Key def! %}%
		%{s% "!%%.Env!" Item[def$E].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MLet False %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[l0e0t1*1].Count 1 %}%
		%{s% "!%%.Env!" Item[l0e0t1*1].Item[1].Key let* %}%
		%{s% "!%%.Env!" Item[let*].Item[1].Value !%%.Fn! %}%

		%{g% "!%%.Env!" RawKeys %%.RawKeys %}%
		%{s% "!%%.RawKeys!" Key[1] +1 %}%
		%{s% "!%%.RawKeys!" Key[2] -1 %}%
		%{s% "!%%.RawKeys!" Key[3] *1 %}%
		%{s% "!%%.RawKeys!" Key[4] /1 %}%
		%{s% "!%%.RawKeys!" Key[5] d0e0f1$1E1 %}%
		%{s% "!%%.RawKeys!" Key[6] l0e0t1*1 %}%
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
		if "!%%.Type!" == "MalSym" (
			%{g% "!%%.ObjMal!" Value %%.Val %}%
			%{% MAIN EncKey "!%%.Val!" %}% %->% %%.Enc
			echo DBG_ENC val=!%%.Val! enc=!%%.Enc!
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
			if "!%%.Ch!" geq "a" if "!%%.Ch!" leq "z" (
				set "%%.Enc=!%%.Enc!!%%.Ch!0"
			) else (
				set "%%.Enc=!%%.Enc!!%%.Ch!1"
			)
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
			%{% MAIN Eval "!%%.Val!" "!%%.NewEnv!" %}% %->% %%.NewVal
			%?% (
				%-|%
			)
			%{s% "!%%.NewEnv!" Item[!%%.RawKey!].Count 1 %}%
			%{s% "!%%.NewEnv!" Item[!%%.RawKey!].Item[1].Key "!%%.RawKey!" %}%
			%{s% "!%%.NewEnv!" Item[!%%.RawKey!].Item[1].Value "!%%.NewVal!" %}%
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
		%{g% "!%%.Env!" RawKeyCount %%.KeyCount %}%
		%{g% "!%%.Env!" RawKeys %%.Keys %}%
		for /l %%i in (1 1 !%%.KeyCount!) do (
			%{g% "!%%.Keys!" Key[%%i] %%.RawKey %}%
			if defined %%.RawKey (
				%{g% "!%%.Env!" "Item[!%%.RawKey!].Count" %%.SameCnt %}%
				if defined %%.SameCnt (
					for /l %%j in (1 1 !%%.SameCnt!) do (
						%{g% "!%%.Env!" "Item[!%%.RawKey!].Item[%%j].Key" %%.KeyMal %}%
						%{g% "!%%.Env!" "Item[!%%.RawKey!].Item[%%j].Value" %%.ValMal %}%
						%{s% "!%%.NewEnv!" Item[!%%.RawKey!].Item[%%j].Key "!%%.KeyMal!" %}%
						%{s% "!%%.NewEnv!" Item[!%%.RawKey!].Item[%%j].Value "!%%.ValMal!" %}%
					)
					%{s% "!%%.NewEnv!" Item[!%%.RawKey!].Count "!%%.SameCnt!" %}%
				)
			)
		)
	)
%-|%

