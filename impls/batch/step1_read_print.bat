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
	!C_Invoke! Str.bat :FromVar _Input
	set "_Str=!G_RET!"
	
	!C_Invoke! :REP _Str
	
	@REM set _
	@REM set G_
	@REM pause
	!C_Invoke! NS.bat :Free !_Str!

	set "G_RET="
	call :ClearLocalVars
goto :Main

:Read _StrMalCode
	set "_StrMalCode=!%~1!"
	
	!C_Invoke! Reader.bat :ReadString _StrMalCode
	set "_ObjMalCode=!G_RET!"

	set "G_RET=!_ObjMalCode!"
	call :ClearLocalVars
goto :eof

:Eval _ObjMalCode
	set "_ObjMalCode=!%~1!"

	set "G_RET=!_ObjMalCode!"
	call :ClearLocalVars
goto :eof

:Print _ObjMalCode
	set "_ObjMalCode=!%~1!"
	
	!C_Invoke! Printer.bat :PrintMalType _ObjMalCode
	set "_StrMalCode=!G_RET!"

	!C_Invoke! IO.bat :WriteStr _StrMalCode

	call :ClearLocalVars
goto :eof

:REP _StrMalCode
	set "_StrMalCode=!%~1!"
	
	!C_Invoke! :Read _StrMalCode
	set "_ObjMalCode=!G_RET!"

	!C_Invoke! :Eval _ObjMalCode
	set "_ObjMalCode=!G_RET!"
	
	!C_Invoke! :Print _ObjMalCode

	set "G_RET="
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
