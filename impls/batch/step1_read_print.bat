@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call :Invoke :Main
exit /b 0


:Main
	set "_Prompt=user> "
	call :Invoke IO.bat :WriteVar _Prompt
	call :Invoke IO.bat :ReadEscapedLine
	set "_Input=!G_RET!"
	call :Invoke Str.bat :FromVar _Input
	set "_Str=!G_RET!"
	
	call :Invoke :REP _Str
	
	@REM set _
	@REM set G_
	@REM pause
	call :Invoke NS.bat :Free !_Str!

	set "G_RET="
	call :ClearLocalVars
goto :Main

:Read _StrMalCode
	set "_StrMalCode=!%~1!"
	
	call :Invoke Reader.bat :ReadString _StrMalCode
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
	
	call :Invoke Printer.bat :PrintMalType _ObjMalCode
	set "_StrMalCode=!G_RET!"

	call :Invoke IO.bat :WriteStr _StrMalCode

	call :ClearLocalVars
goto :eof

:REP _StrMalCode
	set "_StrMalCode=!%~1!"
	
	call :Invoke :Read _StrMalCode
	set "_ObjMalCode=!G_RET!"

	call :Invoke :Eval _ObjMalCode
	set "_ObjMalCode=!G_RET!"
	
	call :Invoke :Print _ObjMalCode

	set "G_RET="
	call :ClearLocalVars
goto :eof

:Invoke
	call SF.Bat :SaveLocalVars
	call %*
	call SF.Bat :RestoreLocalVars
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof