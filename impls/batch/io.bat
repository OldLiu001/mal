@REM Module Name: IO

@rem Export Functions:
@REM 	:ReadEscapedLine
@REM 	:WriteEscapedLineVar _Var
@REM 	:WriteVal _Val
@REM 	:WriteVar _Var
@REM 	:WriteLineVal _Val
@REM 	:WriteErrVal _Val
@REM 	:WriteErrLineVal _Val

@echo off

::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:ReadEscapedLine
	for /f "delims=" %%a in (
		'call Readline.bat'
	) do set "_Input=%%~a"
	set "G_RET=!_Input!"
goto :eof

:WriteEscapedLineVar _Var
	echo."!%~1!"| call WriteAll.bat
goto :eof

:WriteVal _Val
	<nul set /p "=%~1"
goto :eof

:WriteVar _Var
	<nul set /p "=!%~1!"
goto :eof

:WriteStr _Str
	set "_Str=!%~1!"
	call :CopyVar !_Str!.LineCount _LineCount

	for /l %%i in (1 1 !_LineCount!) do (
		call :CopyVar !_Str!.Lines[%%i] _Line
		call :WriteEscapedLineVar _Line
	)

	set "G_RET="
	call :ClearLocalVars
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof

:CopyVar _VarFrom _VarTo
	set "%~2=!%~1!"
goto :eof