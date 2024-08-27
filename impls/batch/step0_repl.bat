@REM @rem Project Name: MAL
@REM @rem Module Name: Main

@REM @rem Origin name mapping:
@REM @rem 	READ -> Read
@REM @rem 	EVAL -> Eval
@REM @rem 	PRINT -> Print
@REM @rem 	rep -> REP

@REM @echo off
@REM pushd "%~dp0"
@REM setlocal ENABLEDELAYEDEXPANSION
@REM call Function.bat :SaveCurrentCallInfo "(Mod)Main"
@REM goto Main


@REM :Main
@REM 	set "_Prompt=user> "
@REM 	call IO.bat :WriteVar _Prompt
@REM 	call IO.bat :ReadEscapedLine
@REM 	call Function.bat :GetRetVar _MalCode
	
@REM 	call Function.bat :PrepareCall _MalCode
@REM 	call :REP
@REM 	call Function.bat :DropRetVar
@REM goto :Main


@REM %Speed Improve Start% (
@REM 	:Read
@REM 		call Function.bat :GetArgs _MalCode
@REM 		call Function.bat :SaveCurrentCallInfo Read

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetVar _MalCode
@REM 	goto :eof

@REM 	:Eval
@REM 		call Function.bat :GetArgs _MalCode
@REM 		call Function.bat :SaveCurrentCallInfo Eval

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetVar _MalCode
@REM 	goto :eof

@REM 	:Print
@REM 		call Function.bat :GetArgs _MalCode
@REM 		call Function.bat :SaveCurrentCallInfo Print
		
@REM 		call IO.bat :WriteEscapedLineVar _MalCode

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetNone
@REM 	goto :eof

@REM 	:REP
@REM 		call Function.bat :GetArgs _MalCode
@REM 		call Function.bat :SaveCurrentCallInfo REP

@REM 		call Function.bat :PrepareCall _MalCode
@REM 		call :READ
@REM 		call Function.bat :GetRetVar _MalCode
		
@REM 		call Function.bat :PrepareCall _MalCode
@REM 		call :EVAL
@REM 		call Function.bat :GetRetVar _MalCode

@REM 		call Function.bat :PrepareCall _MalCode
@REM 		call :PRINT
@REM 		call Function.bat :DropRetVar

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetNone
@REM 	goto :eof
@REM ) %Speed Improve End%

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
goto Main


:Main
	set "_Prompt=user> "
	call IO.bat :WriteVar _Prompt
	call IO.bat :ReadEscapedLine
	call :REP G_RET
goto :Main

:Read _MalCode
	set "G_RET=!%~1!"
goto :eof

:Eval _MalCode
	set "G_RET=!%~1!"
goto :eof

:Print _MalCode
	set "_MalCode=!%~1!"
	
	call IO.bat :WriteEscapedLineVar _MalCode

	set "G_RET="
goto :eof

:REP _MalCode
	set "_MalCode=!%~1!"
	call :READ _MalCode
	call :EVAL G_RET
	call :PRINT G_RET
goto :eof
