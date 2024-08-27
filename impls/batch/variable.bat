@REM @echo off
@REM @REM Module Name: Variable

@REM @rem Export Functions:
@REM @REM 	:CopyVar _VarNameFrom _VarNameTo

@REM ::Start
@REM 	set "_Arguments=%*"
@REM 	if "!_Arguments:~,1!" Equ ":" (
@REM 		Set "_Arguments=!_Arguments:~1!"
@REM 	)
@REM 	call :!_Arguments!
@REM 	set _Arguments=
@REM goto :eof


@REM % Module - Variable - Start % (
@REM 	:CopyVar _VarNameFrom _VarNameTo
@REM 		set "%~2=!%~1!"
@REM 	goto :eof
@REM ) % Module - Variable - End %