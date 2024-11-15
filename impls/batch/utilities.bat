@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%


:UTILITIES_Init MainModName
	set "_G_LEVEL=0"
	set "_G_TRACE=%~1"
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

	set "&=!_C_Copy!"
	set "|=!_C_Invoke!"
	set "->=& !_C_GetRet!"
	set "|->=!_C_GetRet!"
	set "<-=!_C_Return!"
	set "-|=exit /b 0"
	set "?=if defined _G_ERR"
	set "??=!_C_Throw!"
	set "?|=!_C_Fatal!"
%-|%

:UTILITIES_Invoke Mod Fn * -> *
	set /a _G_LEVEL = _G_LEVEL

	set "_G_TRACE_{!_G_LEVEL!}=!_G_TRACE!"
	set "_G_TRACE=!_G_TRACE!>(%~1)%~2"
	set "_G_RET="
	set /a _G_LEVEL += 1

	for /f "tokens=1,2,*" %%a in ('echo.%*') do (
		if defined MAL_BATCH_IMPL_SINGLE_FILE (
			if /i "%%a" == "MAIN" (
				call :MAIN_%%b %%c
			) else (
				call :%%a_%%b %%c
			)
		) else (
			if /i "%%a" == "MAIN" (
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
	
	%&% _G_TRACE_{!_G_LEVEL!} _G_TRACE
	set "_G_TRACE_{!_G_LEVEL!}="
%-|%

:UTILITIES_GetRet Var -> _
	if not defined _G_ERR (
		%&% _G_RET %~1
	)
	set _G_RET=
%-|%

:UTILITIES_Return [Var] -> _
	set _G_RET=
	if "%~1" neq "" if "%~1" neq "_" if defined %~1 (
		%&% %~1 _G_RET
	)
%-|%

:UTILITIES_Fatal Msg
	>&2 echo [!_G_TRACE!] Fatal: %~1
	pause & exit 1
%-|%

:UTILITIES_Throw Msg [Type=Exception] [Data]
	set _G_ERR=_
	set "_G_ERR.Msg=[!_G_TRACE!] !_G_ERR.Type!: %~1"
	if "%~2" neq "" (
		set "_G_ERR.Type=%~2"
	) else (
		set "_G_ERR.Type=Exception"
	)
	if "%~3" neq "_" set "_G_ERR.Data=!%~2!"
%-|%

:UTILITIES_CopyVar From To -> _
	if not defined %~1 (
		!_C_Fatal! "'%~1' undefined."
	)
	set "%~2=!%~1!"
%-|%