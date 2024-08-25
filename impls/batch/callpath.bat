@echo off
@REM Module Name: CallPath

@rem Export Functions:
@REM 	:SaveCurrentCallInfo _Name
@REM 	:RestoreCallInfo

@rem Used Namespaces:
@rem 	G_CallPath

::Start
	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=
goto :eof

% Module - CallPath - Start % (
	:SaveCurrentCallInfo _Name
		call Stackframe.bat :SaveVars G_CallPath
		set "G_CallPath=!G_CallPath! %~1"
	goto :eof

	:RestoreCallInfo
		call Stackframe.bat :GetVars G_CallPath
	goto :eof
) % Module - CallPath - End %