@REM v1.4

@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ("%*") do (
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
!_C_Invoke! MAIN Main
exit /b 0

:MAIN_Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		for /l %%_ in () do (
			set "%%.Prompt=user> " & !_C_Invoke! IO WriteVar %%.Prompt
			!_C_Invoke! IO ReadEscapedLine
			if defined _G_RET (
				!_C_GetRet! %%.Input
			) else (
				goto :Main
			)
			!_C_Invoke! MAIN REP %%.Input
		)
	)
exit /b 0

:MAIN_Read _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Return! %%.Mal
	)
exit /b 0

:MAIN_Eval _Mal -> _Mal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Return! %%.Mal
	)
exit /b 0

:MAIN_Print _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Invoke! IO WriteEscapedLineVar %%.Mal
		!_C_Return! _
	)
exit /b 0

:MAIN_REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		!_C_Invoke! MAIN Read %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! MAIN Eval %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! MAIN Print %%.Mal
		!_C_Return! _
	)
exit /b 0