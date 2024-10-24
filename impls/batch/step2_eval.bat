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

!_C_Invoke! NS New Enviroment & !_C_GetRet! _G_ENV
set "!_G_ENV!.Item[+]=_"
set "!_G_ENV!.Item[+].Count=1"
set "!_G_ENV!.Item[+].Sub[1].Key=+"
!_C_Invoke! TYPES NewBatFn MAIN MAdd True & !_C_GetRet! !_G_ENV!.Item[+].Sub[1].Value
set "!_G_ENV!.Item[-]=_"
set "!_G_ENV!.Item[-].Count=1"
set "!_G_ENV!.Item[-].Sub[1].Key=-"
!_C_Invoke! TYPES NewBatFn MAIN MSub True & !_C_GetRet! !_G_ENV!.Item[-].Sub[1].Value
set "!_G_ENV!.Item[*]=_"
set "!_G_ENV!.Item[*].Count=1"
set "!_G_ENV!.Item[*].Sub[1].Key=*"
!_C_Invoke! TYPES NewBatFn MAIN MMul True & !_C_GetRet! !_G_ENV!.Item[*].Sub[1].Value
set "!_G_ENV!.Item[/]=_"
set "!_G_ENV!.Item[/].Count=1"
set "!_G_ENV!.Item[/].Sub[1].Key=/"
!_C_Invoke! TYPES NewBatFn MAIN MDiv True & !_C_GetRet! !_G_ENV!.Item[/].Sub[1].Value

!_C_Invoke! MAIN Main
exit /b 0

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (
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
			if defined !%%.Env!.Item[!%%.Val!] (
				!_C_Copy! !%%.Env!.Item[!%%.Val!].Count %%.Count
				set "%%.Found=False"
				for /l %%i in (1 1 !%%.Count!) do (
					if "!%%.Found!" neq "True" (
						!_C_Copy! !%%.Env!.Item[!%%.Val!].Sub[%%i].Key %%.Key
						if "!%%.Key!" == "!%%.Val!" (
							!_C_Invoke! Types CopyMalType !%%.Env!.Item[!%%.Val!].Sub[%%i].Value & !_C_GetRet! %%.RetMal
							set "%%.Found=True"
						)
					)
				)
				if "!%%.Found!" == "False" (
					!_C_Throw! Exception _ "Symbol '!%%.Val!' not found."
					!_C_Invoke! TYPES FreeMalType %%.ObjMal
					exit /b 0
				)
				
				!_C_Invoke! TYPES FreeMalType %%.ObjMal

			) else (
				!_C_Throw! Exception _ "Symbol '!%%.Val!' not found."
				!_C_Invoke! TYPES FreeMalType %%.ObjMal
				exit /b 0
			)
		) else if "!%%.Type!" == "MalLst" (
			!_C_Copy! !%%.ObjMal!.Count %%.Count
			if !%%.Count! gtr 0 (
				for /l %%i in (1 1 !%%.Count!) do (
					!_C_Invoke! Main Eval !%%.ObjMal!.Item[%%i] %%.Env & !_C_GetRet! !%%.ObjMal!.Item[%%i]
					if defined _G_ERR (
						!_C_Invoke! TYPES FreeMalType %%.ObjMal
						exit /b 0
					)
				)
				
				!_C_Copy! !%%.ObjMal!.Item[1] %%.Fn
				!_C_Copy! !%%.Fn!.Type %%.Type
				if "!%%.Type!" equ "MalFn" (
					!_C_Copy! !%%.Fn!.Mod %%.Mod
					!_C_Copy! !%%.Fn!.Name %%.Name
					!_C_Invoke! !%%.Mod! !%%.Name! %%.ObjMal & !_C_GetRet! %%.RetMal
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
			!_C_Copy! %%.ObjMal %%.RetMal
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