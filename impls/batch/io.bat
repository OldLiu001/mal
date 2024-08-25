@REM Module Name: IO

@rem Export Functions:
@REM 	:ReadEscapedLine
@REM 	:WriteEscapedLineVar _Var
@REM 	:WriteVal _Val
@REM 	:WriteLineVal _Val
@REM 	:WriteErrVal _Val
@REM 	:WriteErrLineVal _Val

@echo off

::Start
	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=
goto :eof

% Module - IO - Start % (
	:ReadEscapedLine
		for /f "delims=" %%a in (
			'call Readline.bat'
		) do set "_Input=%%~a"
		call Function.bat :RetVar _Input
	goto :eof

	:WriteEscapedLineVar _Var
		echo."!%~1!"| call WriteLine.bat
	goto :eof

	:WriteVal _Val
		set /p "=%~1"<nul
	goto :eof
) % Module - IO - End %