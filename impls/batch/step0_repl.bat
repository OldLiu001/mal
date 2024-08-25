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
	set _Input=
	set /p "=user> "<nul
	for /f "delims=" %%a in ('call Readline.bat') do set "_Input=%%~a"

	set "_MalCode=!_Input!"
	call Stackframe.bat :SaveVars _MalCode
	call :REP
goto :Main


%Speed Improve Start% (
	:Read
		call Stackframe.bat :GetVars _MalCode

		rem return it directly.
		set "_ReturnValue=!_MalCode!"
		
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Eval
		call Stackframe.bat :GetVars _MalCode

		rem return it directly.
		set "_ReturnValue=!_MalCode!"
		
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Print
		call Stackframe.bat :GetVars _MalCode
		
		echo."!_MalCode!"| call writeall.bat

		rem no return value.
	goto :eof

	:REP
		call Stackframe.bat :GetVars _MalCode
		
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

		rem no return value.
	goto :eof
) %Speed Improve End%

