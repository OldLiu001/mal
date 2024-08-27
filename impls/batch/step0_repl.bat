@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION

:Main
	set "_Prompt=user> "
	call IO.bat :WriteVar _Prompt
	call IO.bat :ReadEscapedLine
	call :REP G_RET
	call :ClearLocalVars
goto :Main

:Read _MalCode
	set "G_RET=!%~1!"
	call :ClearLocalVars
goto :eof

:Eval _MalCode
	set "G_RET=!%~1!"
	call :ClearLocalVars
goto :eof

:Print _MalCode
	set "_MalCode=!%~1!"
	call IO.bat :WriteEscapedLineVar _MalCode
	set "G_RET="
	call :ClearLocalVars
goto :eof

:REP _MalCode
	set "_MalCode=!%~1!"
	call :READ _MalCode
	call :EVAL G_RET
	call :PRINT G_RET
	call :ClearLocalVars
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof