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
call Function.bat :SaveCurrentCallInfo "(Mod)Main"
goto Main


:Main
	rem read input.
	set _Input=
	set /p "=user> "<nul
	for /f "delims=" %%a in ('call Readline.bat') do set "_Input=%%~a"

	set "_MalCode=!_Input!"
	call Function.bat :PrepareCall _MalCode
	call :REP
	call Function.bat :DropRetVar
goto :Main


%Speed Improve Start% (
	:Read
		call Function.bat :GetArgs _MalCode
		call Function.bat :SaveCurrentCallInfo Read

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _MalCode
	goto :eof

	:Eval
		call Function.bat :GetArgs _MalCode
		call Function.bat :SaveCurrentCallInfo Eval

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _MalCode
	goto :eof

	:Print
		call Function.bat :GetArgs _MalCode
		call Function.bat :SaveCurrentCallInfo Print
		
		echo."!_MalCode!"| call writeall.bat

		call Function.bat :RestoreCallInfo
		call Function.bat :RetNone
	goto :eof

	:REP
		call Function.bat :GetArgs _MalCode
		call Function.bat :SaveCurrentCallInfo REP

		call Function.bat :PrepareCall _MalCode
		call :READ
		call Function.bat :GetRetVar _MalCode
		
		call Function.bat :PrepareCall _MalCode
		call :EVAL
		call Function.bat :GetRetVar _MalCode

		call Function.bat :PrepareCall _MalCode
		call :PRINT
		call Function.bat :DropRetVar

		call Function.bat :RestoreCallInfo
		call Function.bat :RetNone
	goto :eof
) %Speed Improve End%

