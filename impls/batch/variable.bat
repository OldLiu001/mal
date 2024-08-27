@REM @echo off
@REM @REM Module Name: Variable

@REM @rem Export Functions:
@REM @REM 	:CopyVar _VarNameFrom _VarNameTo

@REM ::Start
@REM 	set "_Args=%*"
@REM 	if "!_Args:~,1!" Equ ":" (
@REM 		Set "_Args=!_Args:~1!"
@REM 	)
@REM 	call :!_Args!
@REM 	set _Args=
@REM goto :eof


@REM % Module - Variable - Start % (
@REM 	:CopyVar _VarNameFrom _VarNameTo
@REM 		set "%~2=!%~1!"
@REM 	goto :eof
@REM ) % Module - Variable - End %