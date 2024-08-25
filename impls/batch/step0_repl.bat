@rem Project Name: MAL
@rem Module Name: Main

@rem Origin name mapping:
@rem 	READ -> Read
@rem 	EVAL -> Eval
@rem 	PRINT -> Print
@rem 	rep -> REP

@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call CallPath.bat :SaveCurrentCallInfo "(Mod)Main"
goto Main


:Main
	rem read input.
	set _Input=
	set /p "=user> "<nul
	for /f "delims=" %%a in ('call Readline.bat') do set "_Input=%%~a"

	set "_MalCode=!_Input!"
	call Stackframe.bat :SaveVars _MalCode
	call :REP
goto :Main


%Speed Improve Start% (
	:Read
		rem get args.
		call Stackframe.bat :GetVars _MalCode

		call CallPath.bat :SaveCurrentCallInfo Read

		rem function body.
		set "_ReturnValue=!_MalCode!"
		
		call CallPath.bat :RestoreCallInfo

		rem return.
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Eval
		rem get args.
		call Stackframe.bat :GetVars _MalCode

		call CallPath.bat :SaveCurrentCallInfo Eval

		rem function body.
		set "_ReturnValue=!_MalCode!"
		
		
		call CallPath.bat :RestoreCallInfo

		rem return.
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Print
		rem get args.
		call Stackframe.bat :GetVars _MalCode
		
		call CallPath.bat :SaveCurrentCallInfo Print
		
		rem function body.
		echo."!_MalCode!"| call writeall.bat

		rem restore call path.
		set G_CallPath
		call CallPath.bat :RestoreCallInfo
		set G_CallPath

		rem return, no return value.
	goto :eof

	:REP
		rem get args.
		call Stackframe.bat :GetVars _MalCode
		
		call CallPath.bat :SaveCurrentCallInfo REP

		call Stackframe.bat :SaveVars _MalCode
		call :READ
		call Stackframe.bat :GetVars _ReturnValue
		
		set "_MalCode=!_ReturnValue!"
		call Stackframe.bat :SaveVars _MalCode
		call :EVAL
		call Stackframe.bat :GetVars _ReturnValue

		set "_MalCode=!_ReturnValue!"
		call Stackframe.bat :SaveVars _MalCode
		call :PRINT

		call CallPath.bat :RestoreCallInfo

		rem return, no return value.
	goto :eof
) %Speed Improve End%

