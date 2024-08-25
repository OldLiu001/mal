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
set "G_CallPath=Main(Module)"
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

		rem set call path.
		call Stackframe.bat :PushVar G_CallPath
		set "G_CallPath=!G_CallPath! Read"

		rem function body.
		set "_ReturnValue=!_MalCode!"
		
		rem restore call path.
		call Stackframe.bat :PopVar G_CallPath

		rem return.
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Eval
		rem get args.
		call Stackframe.bat :GetVars _MalCode

		rem set call path.
		call Stackframe.bat :PushVar G_CallPath
		set "G_CallPath=!G_CallPath! Eval"

		rem function body.
		set "_ReturnValue=!_MalCode!"
		
		
		rem restore call path.
		call Stackframe.bat :PopVar G_CallPath

		rem return.
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Print
		rem get args.
		call Stackframe.bat :GetVars _MalCode
		
		rem set call path.
		call Stackframe.bat :PushVar G_CallPath
		set "G_CallPath=!G_CallPath! Print"
		
		rem function body.
		echo."!_MalCode!"| call writeall.bat

		rem restore call path.
		set G_CallPath
		call Stackframe.bat :PopVar G_CallPath
		set G_CallPath

		rem return, no return value.
	goto :eof

	:REP
		rem get args.
		call Stackframe.bat :GetVars _MalCode
		
		rem set call path.
		call Stackframe.bat :PushVar G_CallPath
		set "G_CallPath=!G_CallPath! REP"

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

		rem restore call path.
		call Stackframe.bat :PopVar G_CallPath

		rem return, no return value.
	goto :eof
) %Speed Improve End%

