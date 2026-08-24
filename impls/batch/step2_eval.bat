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
				( set _G.ERR ) > "%TEMP%\mal_e_!_G.LEVEL!.txt" 2>nul
				for /f "usebackq delims==" %%a in ("%TEMP%\mal_e_!_G.LEVEL!.txt") do set "%%a="
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
		%{s% "!%%.Env!" Item[+].Count 1 %}%
		%{s% "!%%.Env!" Item[+].Item[1].Key + %}%
		%{s% "!%%.Env!" Item[+].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MSub True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[-].Count 1 %}%
		%{s% "!%%.Env!" Item[-].Item[1].Key - %}%
		%{s% "!%%.Env!" Item[-].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MMul True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[*].Count 1 %}%
		%{s% "!%%.Env!" Item[*].Item[1].Key * %}%
		%{s% "!%%.Env!" Item[*].Item[1].Value !%%.Fn! %}%

		%{% TYPES NewBatFn MAIN MDiv True %}% %->% %%.Fn
		%{s% "!%%.Env!" Item[/].Count 1 %}%
		%{s% "!%%.Env!" Item[/].Item[1].Key / %}%
		%{s% "!%%.Env!" Item[/].Item[1].Value !%%.Fn! %}%
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
		set "%%.EnvBody=!%%.Env!"
		if defined !%%.Env!.Target %&% "!%%.Env!.Target" "%%.EnvBody"
		if "!%%.Type!" == "MalSym" (
			%{g% "!%%.ObjMal!" Value %%.Val %}%
			if defined !%%.EnvBody!.Data.Key[Item[!%%.Val!].Count] (
				%{g% "!%%.Env!" Item[!%%.Val!].Count %%.Count %}%
				set "%%.Found=False"
				for /l %%i in (1 1 !%%.Count!) do (
					if "!%%.Found!" neq "True" (
						%{g% "!%%.Env!" Item[!%%.Val!].Item[%%i].Key %%.Key %}%
						if "!%%.Key!" == "!%%.Val!" (
							%{g% "!%%.Env!" Item[!%%.Val!].Item[%%i].Value %%.RetMal %}%
							set "%%.Found=True"
						)
					)
				)
				if "!%%.Found!" == "False" (
					%??% "Symbol '!%%.Val!' not found."
					%-|%
				)
			) else (
				%??% "Symbol '!%%.Val!' not found."
				%-|%
			)
		) else if "!%%.Type!" == "MalLst" (
			%{g% "!%%.ObjMal!" Count %%.Count %}%
			if !%%.Count! gtr 0 (
				for /l %%i in (1 1 !%%.Count!) do (
					%{g% "!%%.ObjMal!" Item[%%i] %%.Item %}%
					%{% MAIN Eval "!%%.Item!" "!%%.Env!" %}% %->% %%.NewItem
					%?% (
						%-|%
					)
					%{s% "!%%.ObjMal!" Item[%%i] "!%%.NewItem!" %}%
				)
				%{g% "!%%.ObjMal!" Item[1] %%.Fn %}%
				%{g% "!%%.Fn!" Type %%.FnType %}%
				if "!%%.FnType!" == "MalFn" (
					%{g% "!%%.Fn!" Mod %%.Mod %}%
					%{g% "!%%.Fn!" Name %%.Name %}%
					call :!%%.Mod!_!%%.Name! "!%%.ObjMal!" %->% %%.RetMal
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

