@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
set "C_Invoke=call :Invoke"
!C_Invoke! :Main
exit /b 0


:Main
	set "_Prompt=user> "
	!C_Invoke! IO.bat :WriteVar _Prompt
	!C_Invoke! IO.bat :ReadEscapedLine
	set "_Input=!G_RET!"
	!C_Invoke! :REP _Input

	set "G_RET="
	call :ClearLocalVars
goto :Main

:Read _MalCode
	set "_MalCode=!%~1!"

	set "G_RET=!_MalCode!"
	call :ClearLocalVars
goto :eof

:Eval _MalCode
	set "_MalCode=!%~1!"

	set "G_RET=!_MalCode!"
	call :ClearLocalVars
goto :eof

:Print _MalCode
	set "_MalCode=!%~1!"

	!C_Invoke! IO.bat :WriteEscapedLineVar _MalCode

	set "G_RET="
	call :ClearLocalVars
goto :eof

:REP _MalCode
	set "_MalCode=!%~1!"
	
	!C_Invoke! :READ _MalCode
	set "_MalCode=!G_RET!"
	!C_Invoke! :EVAL _MalCode
	set "_MalCode=!G_RET!"
	!C_Invoke! :PRINT _MalCode

	call :ClearLocalVars
goto :eof

(
	:Invoke
		if not defined G_TRACE (
			set "G_TRACE=MAIN"
		)
		call SF.Bat :PushVar G_TRACE
		set "G_TMP=%~1"
		if /i "!G_TMP:~,1!" Equ ":" (
			set "G_TRACE=!G_TRACE!>%~1"
		) else (
			set "G_TRACE=!G_TRACE!>%~1>%~2"
		)
		set "G_TMP="
		call SF.Bat :SaveLocalVars
		call %*
		call SF.Bat :RestoreLocalVars
		call SF.Bat :PopVar G_TRACE
	goto :eof

	:ClearLocalVars
		for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
	goto :eof
)
