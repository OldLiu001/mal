@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined MAL_BATCH_IMPL_SINGLE_FILE (
	call UTILITIES :UTILITIES_Init %~n0
) else (
	call :UTILITIES_Init %~n0
)

%|% NS New Enviroment %->% _G_ENV

set "!_G_ENV!.Item[+]=_"
set "!_G_ENV!.Item[+].Count=1"
set "!_G_ENV!.Item[+].Sub[1].Key=+"
%|% TYPES NewBatFn MAIN MAdd True %->% _G_TMP
%|% NS Link _G_ENV Item[+].Sub[1].Value _G_TMP
%|% NS Free _G_TMP

set "!_G_ENV!.Item[-]=_"
set "!_G_ENV!.Item[-].Count=1"
set "!_G_ENV!.Item[-].Sub[1].Key=-"
%|% TYPES NewBatFn MAIN MSub True %->% _G_TMP
%|% NS Link _G_ENV Item[-].Sub[1].Value _G_TMP
%|% NS Free _G_TMP

set "!_G_ENV!.Item[*]=_"
set "!_G_ENV!.Item[*].Count=1"
set "!_G_ENV!.Item[*].Sub[1].Key=*"
%|% TYPES NewBatFn MAIN MMul True %->% _G_TMP
%|% NS Link _G_ENV Item[*].Sub[1].Value _G_TMP
%|% NS Free _G_TMP

set "!_G_ENV!.Item[/]=_"
set "!_G_ENV!.Item[/].Count=1"
set "!_G_ENV!.Item[/].Sub[1].Key=/"
%|% TYPES NewBatFn MAIN MDiv True %->% _G_TMP
%|% NS Link _G_ENV Item[/].Sub[1].Value _G_TMP
%|% NS Free _G_TMP

%|% MAIN Main
%-|%

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (

			set | find /C /V ""

			set "%%.Prompt=user> " & %|% IO WriteVar %%.Prompt
			%|% IO ReadEscapedLine
			if defined _G_RET (
				%|->% %%.Input
				
				%|% Str FromVar %%.Input %->% %%.Str
				
				%|% MAIN REP %%.Str
				%?% (
					if "!_G_ERR.Type!" == "Exception" (
						%|% IO WriteErrLineVar _G_ERR.Msg
					) else if "!_G_ERR.Type!" == "Empty" (
						rem do nothing.
					) else (
						%?|% "Error type '!_G_ERR.Type!' not support."
					)

					for /f "delims==" %%a in (
						'set _G_ERR 2^>nul'
					) do set "%%a="
				)
				
				%|% NS Free %%.Str
			)
		)
	)
%-|%

:MAIN_Read StrMal -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		%|% Reader ReadString %%.StrMal %->% %%.ObjMal
		%?% %-|%

		%<-% %%.ObjMal
	)
%-|%

:MAIN_Eval ObjMal Env -> ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		set "%%.Env=!%~2!"

		%&% !%%.ObjMal!.Type %%.Type

		if "!%%.Type!" == "MalSym" (
			%&% !%%.ObjMal!.Value %%.Val
			if defined !%%.Env!.Item[!%%.Val!] (
				%&% !%%.Env!.Item[!%%.Val!].Count %%.Count
				set "%%.Found=False"
				for /l %%i in (1 1 !%%.Count!) do (
					if "!%%.Found!" neq "True" (
						%&% !%%.Env!.Item[!%%.Val!].Sub[%%i].Key %%.Key
						if "!%%.Key!" == "!%%.Val!" (
							%|% NS Copy !%%.Env!.Item[!%%.Val!].Sub[%%i].Value %->% %%.RetMal
							set "%%.Found=True"
						)
					)
				)
				if "!%%.Found!" == "False" (
					%??% "Symbol '!%%.Val!' not found."
					%|% NS Free %%.ObjMal
					%-|%
				)
				
				%|% NS Free %%.ObjMal

			) else (
				%??% "Symbol '!%%.Val!' not found."
				%|% NS Free %%.ObjMal
				%-|%
			)
		) else if "!%%.Type!" == "MalLst" (
			%&% !%%.ObjMal!.Count %%.Count
			if !%%.Count! gtr 0 (
				for /l %%i in (1 1 !%%.Count!) do (
					%|% Main Eval !%%.ObjMal!.Item[%%i] %%.Env %->% !%%.ObjMal!.Item[%%i]
					%?% (
						%|% NS Free %%.ObjMal
						%-|%
					)
				)
				
				%&% !%%.ObjMal!.Item[1] %%.Fn
				%&% !%%.Fn!.Type %%.Type
				if "!%%.Type!" equ "MalFn" (
					%&% !%%.Fn!.Mod %%.Mod
					%&% !%%.Fn!.Name %%.Name
					%|% !%%.Mod! !%%.Name! %%.ObjMal %->% %%.RetMal
					%|% NS Free %%.ObjMal
				) else (
					%??% "Can not invoke '!%%.Type!'."
					%|% NS Free %%.ObjMal
					%-|%
				)
			) else (
				rem empty list.
				%&% %%.ObjMal %%.RetMal
			)
		) else if "!%%.Type!" == "MalVec" (
			%&% !%%.ObjMal!.Count %%.Count
			for /l %%i in (1 1 !%%.Count!) do (
				%|% Main Eval !%%.ObjMal!.Item[%%i] %%.Env %->% !%%.ObjMal!.Item[%%i]
				%?% (
					%|% NS Free %%.ObjMal
					%-|%
				)
			)
			%&% %%.ObjMal %%.RetMal
		) else if "!%%.Type!" == "MalMap" (
			%&% %%.ObjMal %%.MalMap
			%&% !%%.MalMap!.RawKeyCount %%.KeyCount
			%&% !%%.MalMap!.RawKeys %%.Keys
			
			for /l %%i in (1 1 !%%.KeyCount!) do (
				%&% !%%.Keys!.Key[%%i] %%.RawKey
				
				%&% !%%.MalMap!.Item[!%%.RawKey!].Count %%.SameKeyCount
				
				for /l %%j in (1 1 !%%.SameKeyCount!) do (
					%|% Main Eval !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Value %%.Env
					%|->% !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Value
					%?% (
						%|% NS Free %%.ObjMal
						%-|%
					)
				)
			)
			%&% %%.MalMap %%.RetMal
		) else (
			%&% %%.ObjMal %%.RetMal
		)

		%<-% %%.RetMal
	)
%-|%

:MAIN_Print ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		%|% Printer PrintMalType %%.ObjMal %->% %%.StrMal

		%|% NS Free %%.ObjMal
		
		%|% IO WriteStr %%.StrMal

		%|% NS Free %%.StrMal

		%<-% _
	)
%-|%

:MAIN_REP Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		%|% MAIN Read %%.Mal %->% %%.Mal
		%?% %-|%
		%|% MAIN Eval %%.Mal _G_ENV %->% %%.Mal2
		%?% %-|%
		%|% MAIN Print %%.Mal2
		%<-% _
	)
%-|%



:MAIN_MAdd Mal -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[3] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%&% !%%.Mal!.Item[2] %%.MalNum1
		%&% !%%.Mal!.Item[3] %%.MalNum2
		%&% !%%.MalNum1!.Value %%.Num1
		%&% !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 + %%.Num2
		%|% TYPES NewMal MalNum !%%.Num! %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MSub Mal -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[3] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%&% !%%.Mal!.Item[2] %%.MalNum1
		%&% !%%.Mal!.Item[3] %%.MalNum2
		%&% !%%.MalNum1!.Value %%.Num1
		%&% !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 - %%.Num2
		%|% TYPES NewMal MalNum !%%.Num! %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MMul Mal -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[3] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%&% !%%.Mal!.Item[2] %%.MalNum1
		%&% !%%.Mal!.Item[3] %%.MalNum2
		%&% !%%.MalNum1!.Value %%.Num1
		%&% !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 * %%.Num2
		%|% TYPES NewMal MalNum !%%.Num! %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%

:MAIN_MDiv Mal -> Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[3] MalNum %->% %%.IsNum
		if "!%%.IsNum!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%&% !%%.Mal!.Item[2] %%.MalNum1
		%&% !%%.Mal!.Item[3] %%.MalNum2
		%&% !%%.MalNum1!.Value %%.Num1
		%&% !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 / %%.Num2
		%|% TYPES NewMal MalNum !%%.Num! %->% %%.RetMal
		%<-% %%.RetMal
	)
%-|%