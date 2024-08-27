@REM @echo off
@REM @REM Module Name: Function

@REM @rem Export Functions:
@REM @REM 	:SaveCurrentCallInfo _Name
@REM @REM 	:RestoreCallInfo
@REM @REM 	:PrepareCall _ArgName1 _ArgName2 ...
@REM @REM 	:GetArgs _ParaName1 _ParaName2 ...
@REM @REM 	:RetVar _RetVar
@REM @REM 	:RetVal _RetVal
@REM @REM 	:RetNone
@REM @REM 	:GetRetVar _VarName
@REM @REM 	:DropRetVar

@REM @rem Used Namespaces:
@REM @rem 	G_CallPath

@REM ::Start
@REM 	set "_Arguments=%*"
@REM 	if "!_Arguments:~,1!" Equ ":" (
@REM 		Set "_Arguments=!_Arguments:~1!"
@REM 	)
@REM 	call :!_Arguments!
@REM 	set _Arguments=
@REM goto :eof

@REM % Module - Function - Start % (
@REM 	:SaveCurrentCallInfo _Name
@REM 		if not defined G_CallPath (
@REM 			set "G_CallPath=>"
@REM 		)
@REM 		call Stackframe.bat :SaveVars G_CallPath
@REM 		set "G_CallPath=!G_CallPath!>%~1"
@REM 	goto :eof

@REM 	:RestoreCallInfo
@REM 		call Stackframe.bat :GetVars G_CallPath
@REM 	goto :eof

@REM 	:PrepareCall _ArgName1 _ArgName2 ...
@REM 		call Stackframe.bat :SaveVars %*
@REM 	goto :eof

@REM 	:GetArgs _ParaName1 _ParaName2 ...
@REM 		call Stackframe.bat :GetVars %*
@REM 	goto :eof

@REM 	:RetVar _RetVar
@REM 		set "_ReturnValue=!%~1!"
@REM 		call Stackframe.bat :SaveVars _ReturnValue
@REM 	goto :eof

@REM 	:RetVal _RetVal
@REM 		set "_ReturnValue=%*"
@REM 		call Stackframe.bat :SaveVars _ReturnValue
@REM 	goto :eof

@REM 	:RetNone
@REM 		set "_ReturnValue=_"
@REM 		call Stackframe.bat :SaveVars _ReturnValue
@REM 	goto :eof

@REM 	:GetRetVar _VarName
@REM 		call Stackframe.bat :GetVars _ReturnValue
@REM 		set "%~1=!_ReturnValue!"
@REM 	goto :eof

@REM 	:DropRetVar
@REM 		call Stackframe.bat :GetVars _ReturnValue
@REM 		set _ReturnValue=
@REM 	goto :eof
@REM ) % Module - Function - End %