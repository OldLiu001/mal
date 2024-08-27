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
	call :Invoke :REP _Input

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

	call :Invoke IO.bat :WriteEscapedLineVar _MalCode

	set "G_RET="
	call :ClearLocalVars
goto :eof

:REP _MalCode
	set "_MalCode=!%~1!"
	
	call :Invoke :READ _MalCode
	set "_MalCode=!G_RET!"
	call :Invoke :EVAL _MalCode
	set "_MalCode=!G_RET!"
	call :Invoke :PRINT _MalCode

	call :ClearLocalVars
goto :eof

(
	:Invoke
		call SF.Bat :SaveLocalVars
		call %*
		call SF.Bat :RestoreLocalVars
	goto :eof

	:ClearLocalVars
		for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
	goto :eof
)