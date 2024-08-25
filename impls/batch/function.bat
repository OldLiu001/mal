@echo off
@REM Module Name: Function

@rem Export Functions:
@REM 	:SaveCurrentCallInfo _Name
@REM 	:RestoreCallInfo
@REM 	:PrepareCall _ArgName1 _ArgName2 ...
@REM 	:GetArgs _ParaName1 _ParaName2 ...
@REM 	:RetVar _RetVar
@REM 	:RetVal _RetVal
@REM 	:RetNone
@REM 	:GetRetVar _VarName
@REM 	:DropRetVar

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

% Module - Function - Start % (
	:SaveCurrentCallInfo _Name
		if not defined G_CallPath (
			set "G_CallPath=>"
		)
		call Stackframe.bat :SaveVars G_CallPath
		set "G_CallPath=!G_CallPath!>%~1"
	goto :eof

	:RestoreCallInfo
		call Stackframe.bat :GetVars G_CallPath
	goto :eof

	:PrepareCall _ArgName1 _ArgName2 ...
		call Stackframe.bat :SaveVars %*
	goto :eof

	:GetArgs _ParaName1 _ParaName2 ...
		call Stackframe.bat :GetVars %*
	goto :eof

	:RetVar _RetVar
		set "_ReturnValue=!%~1!"
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:RetVal _RetVal
		set "_ReturnValue=%*"
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:RetNone
		set "_ReturnValue=_"
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:GetRetVar _VarName
		call Stackframe.bat :GetVars _ReturnValue
		set "%~1=!_ReturnValue!"
	goto :eof

	:DropRetVar
		call Stackframe.bat :GetVars _ReturnValue
		set _ReturnValue=
	goto :eof
) % Module - Function - End %