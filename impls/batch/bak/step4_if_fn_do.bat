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

%|% Env New _ %->% _G_ENV
%|% MAIN EnvInit _G_ENV
%|% MAIN Main
%-|%

:MAIN_EnvInit _Env -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Env=!%~1!"
		
		set "%%.Key=+"
		%|% TYPES NewBatFn MAIN MAdd True %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=-"
		%|% TYPES NewBatFn MAIN MSub True %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=*"
		%|% TYPES NewBatFn MAIN MMul True %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=/"
		%|% TYPES NewBatFn MAIN MDiv True %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		
		set "%%.Key=def$E"
		%|% TYPES NewBatFn MAIN MDef False %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=let*"
		%|% TYPES NewBatFn MAIN MLet False %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		
		set "%%.Key=fn*"
		%|% TYPES NewBatFn MAIN MFn False %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=do"
		%|% TYPES NewBatFn MAIN MDo False %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=if"
		%|% TYPES NewBatFn MAIN MIf False %->% %%.MalFn
		%|% Env Set %%.Env %%.Key %%.MalFn
		
		
		%<-% _
	)
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

:MAIN_Read _StrMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		%|% Reader ReadString %%.StrMal %->% %%.ObjMal
		%?% %-|%

		%<-% %%.ObjMal
	)
%-|%

:MAIN_Eval _ObjMal _Env -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		set "%%.Env=!%~2!"

		%&% !%%.ObjMal!.Type %%.Type

		if "!%%.Type!" == "MalSym" (
			%&% !%%.ObjMal!.Value %%.Val
			%|% Env Get %%.Env %%.Val
			%|->% %%.RetMal
			%?% (
				%|% TYPES FreeMalType %%.ObjMal
				%-|%
			)
			%|% TYPES FreeMalType %%.ObjMal
			%|% Types CopyMalType %%.RetMal
			%|->% %%.RetMal
		) else if "!%%.Type!" == "MalLst" (
			%&% !%%.ObjMal!.Count %%.Count
			if !%%.Count! gtr 0 (
				%|% Main Eval !%%.ObjMal!.Item[1] %%.Env %->% !%%.ObjMal!.Item[1]
				%?% (
					%|% TYPES FreeMalType %%.ObjMal
					%-|%
				)
				
				%&% !%%.ObjMal!.Item[1] %%.Fn
				%&% !%%.Fn!.Type %%.Type
				if "!%%.Type!" equ "MalFn" (
					%&% !%%.Fn!.AutoEval %%.AutoEval
					if "!%%.AutoEval!" == "True" (
						for /l %%i in (2 1 !%%.Count!) do (
							%|% Main Eval !%%.ObjMal!.Item[%%i] %%.Env %->% !%%.ObjMal!.Item[%%i]
							%?% (
								%|% TYPES FreeMalType %%.ObjMal
								%-|%
							)
						)
					)
					%&% !%%.Fn!.SubType %%.SubType
					if "!%%.SubType!" == "BAT" (
						%&% !%%.Fn!.Mod %%.Mod
						%&% !%%.Fn!.Name %%.Name
						
						%|% !%%.Mod! !%%.Name! %%.ObjMal %%.Env %->% %%.RetMal
						%|% TYPES FreeMalType %%.ObjMal
					) else (
						%&% !%%.Fn!.Env %%.FnEnv
						%&% !%%.Fn!.Binds %%.Binds
						%&% !%%.Fn!.Body %%.Body
						
						%|% Env New %%.FnEnv %->% %%.NewEnv
						
						rem bind the arguments.
						%&% !%%.Binds!.Count %%.KeyCount
						set /a %%.ValueIndex = 2
						for /l %%i in (1 1 !%%.KeyCount!) do (
							if !%%.ValueIndex! gtr !%%.Count! (
								%??% "Invalid arguments count."
								%|% Env Free %%.NewEnv
								%|% TYPES FreeMalType %%.ObjMal
								%-|%
							)
							%&% !%%.Binds!.Item[%%i] %%.MalKey
							%&% !%%.MalKey!.Value %%.RawKey
							%&% !%%.ObjMal!.Item[!%%.ValueIndex!] %%.MalVal
							%|% Env Set %%.NewEnv %%.RawKey %%.MalVal
							
							set /a %%.ValueIndex += 1
						)
						
						%|% Main Eval %%.Body %%.NewEnv %->% %%.RetMal
						%|% Env Free %%.NewEnv
						%|% TYPES FreeMalType %%.ObjMal
					)
				) else (
					%??% "Can not invoke '!%%.Type!'."
					%|% TYPES FreeMalType %%.ObjMal
					%-|%
				)
			) else (
				rem empty list.
				%&% %%.ObjMal %%.RetMal
			)
		) else if "!%%.Type!" == "MalVec" (
			%|% NS New MalVec %->% %%.RetMal
			%&% !%%.ObjMal!.Count %%.Count
			%&% !%%.ObjMal!.Count !%%.RetMal!.Count
			for /l %%i in (1 1 !%%.Count!) do (
				%|% Main Eval !%%.ObjMal!.Item[%%i] %%.Env %->% !%%.RetMal!.Item[%%i]
				%?% (
					%|% TYPES FreeMalType %%.ObjMal
					%|% TYPES FreeMalType %%.RetMal
					%-|%
				)
			)
			%|% Types FreeMalType %%.ObjMal
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
						%|% TYPES FreeMalType %%.ObjMal
						%-|%
					)
				)
			)
			%&% %%.MalMap %%.RetMal
		) else (
			%|% Types CopyMalType %%.ObjMal %->% %%.RetMal
			%|% TYPES FreeMalType %%.ObjMal
		)

		%<-% %%.RetMal
	)
%-|%

:MAIN_Print _ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		%|% Printer PrintMalType %%.ObjMal %->% %%.StrMal

		%|% TYPES FreeMalType %%.ObjMal
		
		%|% IO WriteStr %%.StrMal

		%|% NS Free %%.StrMal

		%<-% _
	)
%-|%

:MAIN_REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		%|% MAIN Read %%.Mal %->% %%.Mal
		%?% %-|%
		%|% MAIN Eval %%.Mal _G_ENV %->% %%.Mal
		%?% %-|%
		%|% MAIN Print %%.Mal
		%<-% _
	)
%-|%



:MAIN_MAdd _Mal -> _Mal
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

:MAIN_MSub _Mal -> _Mal
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

:MAIN_MMul _Mal -> _Mal
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

:MAIN_MDiv _Mal -> _Mal
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

:Main_MDef _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalSym %->% %%.CheckResult
		if "!%%.CheckResult!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%&% !%%.Mal!.Item[2] %%.Sym
		%&% !%%.Sym!.Value %%.Key
		%&% !%%.Mal!.Item[3] %%.Val
		
		%|% Main Eval %%.Val %%.Env %->% %%.NewVal
		%?% %-|%
		
		%|% Types CopyMalType %%.NewVal %->% %%.CopiedVal
		%|% Env Set %%.Env %%.Key %%.CopiedVal
		%<-% %%.NewVal
	)
%-|%

:Main_MLet _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalLst MalVec %->% %%.CheckResult
		if "!%%.CheckResult!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		
		%&% !%%.Mal!.Item[2] %%.BindList
		%&% !%%.BindList!.Count %%.BindCount
		set /a "%%.IsOdd = %%.BindCount & 1"
		if !%%.IsOdd! equ 1 (
			%??% "The binding list is not valid and should have an even number of elements."
			%-|%
		)
		
		%|% Env New %%.Env %->% %%.NewEnv
		for /l %%i in (1 2 !%%.BindCount!) do (
			set /a %%.KeyIndex = %%i
			set /a %%.ValIndex = %%i + 1
			
			%&% !%%.BindList!.Item[!%%.KeyIndex!] %%.Key
			%&% !%%.BindList!.Item[!%%.ValIndex!] %%.Val
			
			%|% TYPES CheckType %%.Key MalSym %->% %%.CheckResult
			if "!%%.CheckResult!" neq "True" (
				%??% "Invalid binding list key type, expect 'MalSym'."
				%-|%
			)
			%&% !%%.Key!.Value %%.RawKey
			%|% Main Eval %%.Val %%.NewEnv %->% %%.Val
			%?% (
				%|% Env Free %%.NewEnv
				%-|%
			)
			
			%|% Env Set %%.NewEnv %%.RawKey %%.Val
		)
		
		%|% Main Eval !%%.Mal!.Item[3] %%.NewEnv %->% %%.RetMal
		%?% (
			%|% Env Free %%.NewEnv
			%-|%
		)
		%|% Env Free %%.NewEnv
		%<-% %%.RetMal
	)
%-|%

:MAIN_MFn _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% TYPES CheckType !%%.Mal!.Item[2] MalLst MalVec %->% %%.CheckResult
		if "!%%.CheckResult!" neq "True" (
			%??% "Invalid argument type."
			%-|%
		)
		%&% !%%.Mal!.Item[2] %%.Binds
		%&% !%%.Binds!.Count %%.BindCnt
		for /l %%i in (1 1 !%%.BindCnt!) do (
			%|% TYPES CheckType !%%.Binds!.Item[%%i] MalSym
			%|->% %%.CheckResult
			if "!%%.CheckResult!" neq "True" (
				%??% "Invalid argument type."
				%-|%
			)
		)
		
		%|% NS New MalFn %->% %%.MalFn
		set "!%%.MalFn!.SubType=MAL"
		set "!%%.MalFn!.AutoEval=True"
		%|% Types CopyMalType %%.Binds %->% !%%.MalFn!.Binds
		%|% Types CopyMalType !%%.Mal!.Item[3] %->% !%%.MalFn!.Body
	)
		:MAIN_MFn_Loop
	for %%. in (_L{!_G_LEVEL!}_) do (
			echo !%%.Env! loop
			%&% !%%.Env!.RefCount %%.RefCount
			set /a %%.RefCount += 1
			%&% %%.RefCount !%%.Env!.RefCount
			%&% %%.Env !%%.MalFn!.Env
			%&% !%%.Env!.Outer %%.Env
			echo !%%.Env!
			set !%%.Env!
			echo !%%.Env! loophead
		echo if "!%%.Env!" neq "_" goto MAIN_MFn_Loop
		if "!%%.Env!" neq "_" goto MAIN_MFn_Loop
		set "!%%.MalFn!.AutoEval=True"
		%<-% %%.MalFn
	)
%-|%

:MAIN_MDo _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! lss 2 (
			%??% "Invalid arguments count."
			%-|%
		)
		for /l %%i in (2 1 !%%.Count!) do (
			%|-% Main Eval !%%.Mal!.Item[%%i] %%.Env %->% %%.RetMal
			%?% %-|%
			if %%i neq !%%.Count! (
				%|% TYPES FreeMalType %%.RetMal
			)
		)
		%<-% %%.RetMal
	)
%-|%


:MAIN_MIf _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		%&% !%%.Mal!.Count %%.Count
		if !%%.Count! neq 4 (
			%??% "Invalid arguments count."
			%-|%
		)
		%|% Main Eval !%%.Mal!.Item[2] %%.Env %->% %%.CondMal
		%?% %-|%
		%&% !%%.CondMal!.Type %%.Type
		set %%.Cond=True
		if "!%%.Type!" == "MalNil" (
			set %%.Cond=False
		) else if "!%%.Type!" == "MalBool" (
			%&% !%%.CondMal!.Value %%.Val
			if "!%%.Val!" == "false" (
				set %%.Cond=False
			)
		)
		%|% TYPES FreeMalType %%.CondMal
		
		if "!%%.Cond!" equ "True" (
			%|% Main Eval !%%.Mal!.Item[3] %%.Env %->% %%.RetMal
		) else (
			%|% Main Eval !%%.Mal!.Item[4] %%.Env %->% %%.RetMal
		)
		%<-% %%.RetMal
	)
%-|%