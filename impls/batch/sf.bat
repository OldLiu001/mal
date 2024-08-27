@echo off

::Start
	rem If G_SP is not defined, then set it to 0.
	set /a G_SP = G_SP

	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:PushVar _VarName
	set /a G_SP += 1
	set "G_SF[!G_SP!]=!%~1!"
goto :eof

:PushVal _Value
	set /a G_SP += 1
	set "G_SF[!G_SP!]=%~1"
goto :eof

:PopVar _VarName
	if %G_SP% leq 0 (
		>&2 echo Stack is empty.
		pause & exit 1
	)
	for %%i in (!G_SP!) do (
		set "%~1=!G_SF[%%i]!"
		set "G_SF[%%i]="
	)
	set /a G_SP -= 1
goto :eof

:SaveLocalVars
	set "G_TMP=0"
	for /f "delims==" %%i in ('set _ 2^>nul') do (
		call :PushVar %%i
		call :PushVal %%i
		set /a G_TMP += 1
	)
	call :PushVal !G_TMP!
	set "G_TMP="
goto :eof

:RestoreLocalVars
	call :PopVar G_TMP_COUNT
	for /l %%i in (1 1 !G_TMP_COUNT!) do (
		call :PopVar G_TMP_VARNAME
		call :PopVar !G_TMP_VARNAME!
	)
	set "G_TMP_COUNT="
	set "G_TMP_VARNAME="
goto :eof