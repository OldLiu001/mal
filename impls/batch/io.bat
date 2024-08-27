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

% Module - IO - Start % (
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
) % Module - IO - End %