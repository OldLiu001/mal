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
							!_C_Copy! !%%.Env!.Item[!%%.Val!].Sub[%%i].Value %%.RetMal
							set "%%.Found=True"
						)
					)
				)
				if "!%%.Found!" == "False" (
					!_C_Throw! Exception _ "Symbol '!%%.Val!' not found."
				)
				
				!_C_Invoke! TYPES FreeMalType %%.ObjMal

			) else (
				!_C_Throw! Exception _ "Symbol '!%%.Val!' not found."
			)
		) else if "!%%.Type!" == "MalLst" (
			!_C_Fatal! TODO
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