@echo off
@REM Module Name: Variable

@rem Export Functions:
@REM 	:CopyVar _VarNameFrom _VarNameTo

::Start
	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=
goto :eof


% Module - Variable - Start % (
	:CopyVar _VarNameFrom _VarNameTo
		set "%~2=!%~1!"
	goto :eof
) % Module - Variable - End %