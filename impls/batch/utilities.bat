
	@REM Version 1.5

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0


:UTILITIES_Init _MainModName
	set "_G_LEVEL=0"
	set "_G_TRACE=>%~1"
	set "_G_RET="
	set "_G_ERR="
	set "_G_MAIN=%~1"

	if defined MAL_BATCH_IMPL_SINGLE_FILE (
		set "_C_Invoke=call :UTILITIES_Invoke"
		set "_C_Copy=call :UTILITIES_CopyVar"
		set "_C_GetRet=call :UTILITIES_GetRet"
		set "_C_Return=call :UTILITIES_Return"
		set "_C_Fatal=call :UTILITIES_Fatal"
		set "_C_Throw=call :UTILITIES_Throw"
	) else (
		set "_C_Invoke=call UTILITIES :UTILITIES_Invoke"
		set "_C_Copy=call UTILITIES :UTILITIES_CopyVar"
		set "_C_GetRet=call UTILITIES :UTILITIES_GetRet"
		set "_C_Return=call UTILITIES :UTILITIES_Return"
		set "_C_Fatal=call UTILITIES :UTILITIES_Fatal"
		set "_C_Throw=call UTILITIES :UTILITIES_Throw"
	)
exit /b 0

:UTILITIES_Invoke _Mod _Fn * -> *
	set /a _G_LEVEL = _G_LEVEL
	if not defined _G_TRACE (
		set "_G_TRACE=>"
	)

	set "_G_TRACE_{!_G_LEVEL!}=!_G_TRACE!"
	set "_G_TRACE=!_G_TRACE!>(%~1)%~2"
	set "_G_RET="
	set /a _G_LEVEL += 1

	for /f "tokens=1,2,*" %%a in ("%*") do (
		if defined MAL_BATCH_IMPL_SINGLE_FILE (
			if "%%a" == "MAIN" (
				call :MAIN_%%b %%c
			) else (
				call :%%a_%%b %%c
			)
		) else (
			if "%%a" == "MAIN" (
				call !_G_MAIN! CALL_SELF :MAIN_%%b %%c
			) else (
				call %%a :%%a_%%b %%c
			)
		)
	)
	
	for /f "delims==" %%a in (
		'set _L{!_G_LEVEL!}_ 2^>nul'
	) do set "%%a="

	set /a _G_LEVEL -= 1
	
	!_C_Copy! _G_TRACE_{!_G_LEVEL!} _G_TRACE
	set "_G_TRACE_{!_G_LEVEL!}="
exit /b 0

:UTILITIES_GetRet _Var -> _
	if not defined _G_ERR (
		!_C_Copy! _G_RET %~1
	)
	set _G_RET=
exit /b 0

:UTILITIES_Return _Var -> _
	set _G_RET=
	if "%~1" neq "" if "%~1" neq "_" if defined %~1 (
		!_C_Copy! %~1 _G_RET
	)
exit /b 0

:UTILITIES_Fatal _Msg
	>&2 echo [!_G_TRACE!] Fatal: %~1
	pause & exit 1
exit /b 0

:UTILITIES_Throw _Type _Data _Msg
	set _G_ERR=_
	set "_G_ERR.Type=%~1"
	if "%~2" neq "_" set "_G_ERR.Data=!%~2!"
	set "_G_ERR.Msg=[!_G_TRACE!] !_G_ERR.Type!: %~3"
exit /b 0

:UTILITIES_CopyVar _VarFrom _VarTo -> _
	if not defined %~1 (
		!_C_Fatal! "'%~1' undefined."
	)
	set "%~2=!%~1!"
exit /b 0