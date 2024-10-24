@REM v:1.4

@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || !_C_Fatal! "Call '%~nx0' failed."
	)
	exit /b 0
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined MAL_BATCH_IMPL_SINGLE_FILE (
	call UTILITIES :UTILITIES_Init %~n0
) else (
	call :UTILITIES_Init %~n0
)

!_C_Invoke! Env New _ & !_C_GetRet! _G_ENV
!_C_Invoke! MAIN EnvInit _G_ENV
set !_G_ENV!
!_C_Invoke! MAIN Main
exit /b 0

:MAIN_EnvInit _Env -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Env=!%~1!"
		
		set "%%.Key=+"
		!_C_Invoke! TYPES NewBatFn MAIN MAdd True & !_C_GetRet! %%.MalFn
		!_C_Invoke! Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=-"
		!_C_Invoke! TYPES NewBatFn MAIN MSub True & !_C_GetRet! %%.MalFn
		!_C_Invoke! Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=*"
		!_C_Invoke! TYPES NewBatFn MAIN MMul True & !_C_GetRet! %%.MalFn
		!_C_Invoke! Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=/"
		!_C_Invoke! TYPES NewBatFn MAIN MDiv True & !_C_GetRet! %%.MalFn
		!_C_Invoke! Env Set %%.Env %%.Key %%.MalFn
		
		set "%%.Key=def$E"
		!_C_Invoke! TYPES NewBatFn MAIN MDef False & !_C_GetRet! %%.MalFn
		!_C_Invoke! Env Set %%.Env %%.Key %%.MalFn
		set "%%.Key=let*"
		!_C_Invoke! TYPES NewBatFn MAIN MLet False & !_C_GetRet! %%.MalFn
		!_C_Invoke! Env Set %%.Env %%.Key %%.MalFn
		!_C_Return! _
	)
exit /b 0

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (
			set | find /C /V ""
			set "%%.Prompt=user> " & !_C_Invoke! IO WriteVar %%.Prompt
			!_C_Invoke! IO ReadEscapedLine
			if defined _G_RET (
				!_C_GetRet! %%.Input
				
				!_C_Invoke! Str FromVar %%.Input & !_C_GetRet! %%.Str
				
				!_C_Invoke! MAIN REP %%.Str
				if defined _G_ERR (
					if "!_G_ERR.Type!" == "Exception" (
						!_C_Invoke! IO WriteErrLineVar _G_ERR.Msg
					) else if "!_G_ERR.Type!" == "Empty" (
						rem do nothing.
					) else (
						!_C_Fatal! "Error type '!_G_ERR.Type!' not support."
					)

					for /f "delims==" %%a in (
						'set _G_ERR 2^>nul'
					) do set "%%a="
				)
				
				!_C_Invoke! NS Free %%.Str
			)
		)
	)
exit /b 0

:MAIN_Read _StrMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		!_C_Invoke! Reader ReadString %%.StrMal & !_C_GetRet! %%.ObjMal
		if defined _G_ERR exit /b 0

		!_C_Return! %%.ObjMal
	)
exit /b 0

:MAIN_Eval _ObjMal _Env -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		set "%%.Env=!%~2!"

		!_C_Copy! !%%.ObjMal!.Type %%.Type

		if "!%%.Type!" == "MalSym" (
			!_C_Copy! !%%.ObjMal!.Value %%.Val
			!_C_Invoke! Env Get %%.Env %%.Val
			!_C_GetRet! %%.RetMal
			if defined _G_ERR (
				!_C_Invoke! TYPES FreeMalType %%.ObjMal
				exit /b 0
			)
			!_C_Invoke! TYPES FreeMalType %%.ObjMal
			!_C_Invoke! Types CopyMalType %%.RetMal
			!_C_GetRet! %%.RetMal
		) else if "!%%.Type!" == "MalLst" (
			!_C_Copy! !%%.ObjMal!.Count %%.Count
			if !%%.Count! gtr 0 (
				!_C_Invoke! Main Eval !%%.ObjMal!.Item[1] %%.Env & !_C_GetRet! !%%.ObjMal!.Item[1]
				if defined _G_ERR (
					!_C_Invoke! TYPES FreeMalType %%.ObjMal
					exit /b 0
				)
				
				!_C_Copy! !%%.ObjMal!.Item[1] %%.Fn
				!_C_Copy! !%%.Fn!.Type %%.Type
				if "!%%.Type!" equ "MalFn" (
					!_C_Copy! !%%.Fn!.Mod %%.Mod
					!_C_Copy! !%%.Fn!.Name %%.Name
					!_C_Copy! !%%.Fn!.AutoEval %%.AutoEval
					if "!%%.AutoEval!" == "True" (
						for /l %%i in (2 1 !%%.Count!) do (
							!_C_Invoke! Main Eval !%%.ObjMal!.Item[%%i] %%.Env & !_C_GetRet! !%%.ObjMal!.Item[%%i]
							if defined _G_ERR (
								!_C_Invoke! TYPES FreeMalType %%.ObjMal
								exit /b 0
							)
						)
					)
					
					!_C_Invoke! !%%.Mod! !%%.Name! %%.ObjMal %%.Env & !_C_GetRet! %%.RetMal
					!_C_Invoke! TYPES FreeMalType %%.ObjMal
				) else (
					!_C_Throw! Exception _ "Can not invoke '!%%.Type!'."
					!_C_Invoke! TYPES FreeMalType %%.ObjMal
					exit /b 0
				)
			) else (
				rem empty list.
				!_C_Copy! %%.ObjMal %%.RetMal
			)
		) else if "!%%.Type!" == "MalVec" (
			!_C_Fatal! "TODO: rewrite this to create new vec and free old vec"
			!_C_Copy! !%%.ObjMal!.Count %%.Count
			for /l %%i in (1 1 !%%.Count!) do (
				!_C_Invoke! Main Eval !%%.ObjMal!.Item[%%i] %%.Env & !_C_GetRet! !%%.ObjMal!.Item[%%i]
				if defined _G_ERR (
					!_C_Invoke! TYPES FreeMalType %%.ObjMal
					exit /b 0
				)
			)
			!_C_Copy! %%.ObjMal %%.RetMal
		) else if "!%%.Type!" == "MalMap" (
			!_C_Copy! %%.ObjMal %%.MalMap
			!_C_Copy! !%%.MalMap!.RawKeyCount %%.KeyCount
			!_C_Copy! !%%.MalMap!.RawKeys %%.Keys
			
			for /l %%i in (1 1 !%%.KeyCount!) do (
				!_C_Copy! !%%.Keys!.Key[%%i] %%.RawKey
				
				!_C_Copy! !%%.MalMap!.Item[!%%.RawKey!].Count %%.SameKeyCount
				
				for /l %%j in (1 1 !%%.SameKeyCount!) do (
					!_C_Invoke! Main Eval !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Value %%.Env
					!_C_GetRet! !%%.MalMap!.Item[!%%.RawKey!].Item[%%j].Value
					if defined _G_ERR (
						!_C_Invoke! TYPES FreeMalType %%.ObjMal
						exit /b 0
					)
				)
			)
			!_C_Copy! %%.MalMap %%.RetMal
		) else (
			!_C_Invoke! Types CopyMalType %%.ObjMal & !_C_GetRet! %%.RetMal
			!_C_Invoke! TYPES FreeMalType %%.ObjMal
		)

		!_C_Return! %%.RetMal
	)
exit /b 0

:MAIN_Print _ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		!_C_Invoke! Printer PrintMalType %%.ObjMal & !_C_GetRet! %%.StrMal

		!_C_Invoke! TYPES FreeMalType %%.ObjMal
		
		!_C_Invoke! IO WriteStr %%.StrMal

		!_C_Invoke! NS Free %%.StrMal

		!_C_Return! _
	)
exit /b 0

:MAIN_REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		!_C_Invoke! MAIN Read %%.Mal & !_C_GetRet! %%.Mal
		if defined _G_ERR exit /b 0
		!_C_Invoke! MAIN Eval %%.Mal _G_ENV & !_C_GetRet! %%.Mal
		if defined _G_ERR exit /b 0
		!_C_Invoke! MAIN Print %%.Mal
		!_C_Return! _
	)
exit /b 0



:MAIN_MAdd _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			!_C_Throw! Exception _ "Invalid arguments count."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[2] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[3] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Copy! !%%.Mal!.Item[2] %%.MalNum1
		!_C_Copy! !%%.Mal!.Item[3] %%.MalNum2
		!_C_Copy! !%%.MalNum1!.Value %%.Num1
		!_C_Copy! !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 + %%.Num2
		!_C_Invoke! TYPES NewMal MalNum !%%.Num! & !_C_GetRet! %%.RetMal
		!_C_Return! %%.RetMal
	)
exit /b 0

:MAIN_MSub _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			!_C_Throw! Exception _ "Invalid arguments count."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[2] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[3] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Copy! !%%.Mal!.Item[2] %%.MalNum1
		!_C_Copy! !%%.Mal!.Item[3] %%.MalNum2
		!_C_Copy! !%%.MalNum1!.Value %%.Num1
		!_C_Copy! !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 - %%.Num2
		!_C_Invoke! TYPES NewMal MalNum !%%.Num! & !_C_GetRet! %%.RetMal
		!_C_Return! %%.RetMal
	)
exit /b 0

:MAIN_MMul _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			!_C_Throw! Exception _ "Invalid arguments count."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[2] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[3] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Copy! !%%.Mal!.Item[2] %%.MalNum1
		!_C_Copy! !%%.Mal!.Item[3] %%.MalNum2
		!_C_Copy! !%%.MalNum1!.Value %%.Num1
		!_C_Copy! !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 * %%.Num2
		!_C_Invoke! TYPES NewMal MalNum !%%.Num! & !_C_GetRet! %%.RetMal
		!_C_Return! %%.RetMal
	)
exit /b 0

:MAIN_MDiv _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Copy! !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			!_C_Throw! Exception _ "Invalid arguments count."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[2] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[3] MalNum & !_C_GetRet! %%.IsNum
		if "!%%.IsNum!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Copy! !%%.Mal!.Item[2] %%.MalNum1
		!_C_Copy! !%%.Mal!.Item[3] %%.MalNum2
		!_C_Copy! !%%.MalNum1!.Value %%.Num1
		!_C_Copy! !%%.MalNum2!.Value %%.Num2
		set /a %%.Num = %%.Num1 / %%.Num2
		!_C_Invoke! TYPES NewMal MalNum !%%.Num! & !_C_GetRet! %%.RetMal
		!_C_Return! %%.RetMal
	)
exit /b 0

:Main_MDef _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		!_C_Copy! !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			!_C_Throw! Exception _ "Invalid arguments count."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[2] MalSym & !_C_GetRet! %%.CheckResult
		if "!%%.CheckResult!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		!_C_Copy! !%%.Mal!.Item[2] %%.Sym
		!_C_Copy! !%%.Sym!.Value %%.Key
		!_C_Copy! !%%.Mal!.Item[3] %%.Val
		
		!_C_Invoke! Main Eval %%.Val %%.Env & !_C_GetRet! %%.NewVal
		if defined _G_ERR exit /b 0
		
		!_C_Invoke! Types CopyMalType %%.NewVal & !_C_GetRet! %%.CopiedVal
		!_C_Invoke! Env Set %%.Env %%.Key %%.CopiedVal
		!_C_Return! %%.NewVal
	)
exit /b 0

:Main_MLet _Mal _Env -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		set "%%.Env=!%~2!"
		!_C_Copy! !%%.Mal!.Count %%.Count
		if !%%.Count! neq 3 (
			!_C_Throw! Exception _ "Invalid arguments count."
			exit /b 0
		)
		!_C_Invoke! TYPES CheckType !%%.Mal!.Item[2] MalLst MalVec & !_C_GetRet! %%.CheckResult
		if "!%%.CheckResult!" neq "True" (
			!_C_Throw! Exception _ "Invalid argument type."
			exit /b 0
		)
		
		!_C_Copy! !%%.Mal!.Item[2] %%.BindList
		!_C_Copy! !%%.BindList!.Count %%.BindCount
		set /a "%%.IsOdd = %%.BindCount & 1"
		if !%%.IsOdd! equ 1 (
			!_C_Throw! Exception _ "The binding list is not valid and should have an even number of elements."
			exit /b 0
		)
		
		!_C_Invoke! Env New %%.Env & !_C_GetRet! %%.NewEnv
		for /l %%i in (1 2 !%%.BindCount!) do (
			set /a %%.KeyIndex = %%i
			set /a %%.ValIndex = %%i + 1
			
			!_C_Copy! !%%.BindList!.Item[!%%.KeyIndex!] %%.Key
			!_C_Copy! !%%.BindList!.Item[!%%.ValIndex!] %%.Val
			
			!_C_Invoke! TYPES CheckType %%.Key MalSym & !_C_GetRet! %%.CheckResult
			if "!%%.CheckResult!" neq "True" (
				!_C_Throw! Exception _ "Invalid binding list key type, expect 'MalSym'."
				exit /b 0
			)
			!_C_Copy! !%%.Key!.Value %%.RawKey
			!_C_Invoke! Main Eval %%.Val %%.NewEnv & !_C_GetRet! %%.Val
			if defined _G_ERR (
				!_C_Invoke! Env Free %%.NewEnv
				exit /b 0
			)
			
			!_C_Invoke! Env Set %%.NewEnv %%.RawKey %%.Val
		)
		
		!_C_Invoke! Main Eval !%%.Mal!.Item[3] %%.NewEnv & !_C_GetRet! %%.RetMal
		if defined _G_ERR (
			!_C_Invoke! Env Free %%.NewEnv
			exit /b 0
		)
		!_C_Invoke! Env Free %%.NewEnv
		!_C_Return! %%.RetMal
	)
exit /b 0