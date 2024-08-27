@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
goto Main


:Main
	set "_Prompt=user> "
	call IO.bat :WriteVar _Prompt
	
	call IO.bat :ReadEscapedLine
	call Str.bat :New G_RET
	set "_Str=!G_RET!"
	
	call SF.bat :SaveLocalVars
	call :REP _Str
	call SF.bat :RestoreLocalVars
	
	call NS.bat :Free !_StrMalCode!
	call :ClearLocalVars
goto :Main

:Read _StrMalCode
	set "_StrMalCode=!%~1!"
	
	call Reader.bat :ReadString _StrMalCode
	call :ClearLocalVars
goto :eof

:Eval _ObjMalCode
	set "G_RET=!%~1!"
	call :ClearLocalVars
goto :eof

:Print _ObjMalCode
	set "_ObjMalCode=!%~1!"
	
	call Printer.bat :PrintMalType _ObjMalCode
	@REM call Function.bat :GetRetVar _StrMalCode
	
	@REM call Variable.bat :CopyVar !_StrMalCode!.LineCount _LineCount
	@REM for /l %%i in (1 1 !_LineCount!) do (
	@REM 	call Variable.bat :CopyVar !_StrMalCode!.Lines[%%i] _Line
	@REM 	call IO.bat :WriteEscapedLineVar _Line
	@REM )

	@REM call Function.bat :RestoreCallInfo
	@REM call Function.bat :RetNone
	call :ClearLocalVars
goto :eof

:REP _StrMalCode
	set "_StrMalCode=!%~1!"
	
	call :Read _StrMalCode
	call :EVAL G_RET
	call :PRINT G_RET
	call :ClearLocalVars
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof