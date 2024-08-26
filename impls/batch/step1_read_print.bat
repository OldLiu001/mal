::TODO: rewrite this & consider string wrap

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
@REM set "G_CallPath=Main(Module)"
@REM goto Main


@REM :Main
@REM 	rem read input.
@REM 	set _Input=
@REM 	set /p "=user> "<nul
@REM 	for /f "delims=" %%a in ('call Readline.bat') do set "_Input=%%~a"

@REM 	rem wrap an string.
@REM 	call Namespace.bat :New
@REM 	call Stackframe.bat :GetVars _ReturnValue
@REM 	set "_StrMalCode=!_ReturnValue!"
@REM 	set "!_StrMalCode!.LineCount=1"
@REM 	set "!_StrMalCode!.Lines[1]=!_Input!"
@REM 	call Stackframe.bat :SaveVars _StrMalCode

@REM 	set "_MalCode=!_StrMalCode!"
@REM 	call Stackframe.bat :SaveVars _MalCode
@REM 	call :REP

@REM 	rem free string.
@REM 	call Stackframe.bat :GetVars _StrMalCode
@REM 	call Namespace.bat :Free !_StrMalCode!
@REM goto :Main


@REM %Speed Improve Start% (
@REM 	:Read
@REM 		rem get args.
@REM 		call Stackframe.bat :GetVars _MalCode

@REM 		rem set call path.
@REM 		call Stackframe.bat :SaveVars G_CallPath
@REM 		set "G_CallPath=!G_CallPath! Read"

@REM 		rem function body.
@REM 		(
@REM 			set "_StrMalCode=!_MalCode!"
@REM 			call Stackframe.bat :SaveVars _StrMalCode
@REM 			call reader.bat :ReadString
@REM 			call Stackframe.bat :GetVars _ReturnValue
@REM 		)
		
@REM 		rem restore call path.
@REM 		call Stackframe.bat :GetVars G_CallPath

@REM 		rem return.
@REM 		call Stackframe.bat :SaveVars _ReturnValue
@REM 	goto :eof

@REM 	:Eval
@REM 		rem get args.
@REM 		call Stackframe.bat :GetVars _MalCode

@REM 		rem set call path.
@REM 		call Stackframe.bat :SaveVars G_CallPath
@REM 		set "G_CallPath=!G_CallPath! Eval"

@REM 		rem function body.
@REM 		set "_ReturnValue=!_MalCode!"
		
		
@REM 		rem restore call path.
@REM 		call Stackframe.bat :GetVars G_CallPath

@REM 		rem return.
@REM 		call Stackframe.bat :SaveVars _ReturnValue
@REM 	goto :eof

@REM 	:Print
@REM 		rem get args.
@REM 		call Stackframe.bat :GetVars _MalCode
		
@REM 		rem set call path.
@REM 		call Stackframe.bat :SaveVars G_CallPath
@REM 		set "G_CallPath=!G_CallPath! Print"
		
@REM 		rem function body.
@REM 		echo."!_MalCode!"| call writeall.bat

@REM 		rem restore call path.
@REM 		set G_CallPath
@REM 		call Stackframe.bat :GetVars G_CallPath
@REM 		set G_CallPath

@REM 		rem return, no return value.
@REM 	goto :eof

@REM 	:REP
@REM 		rem get args.
@REM 		call Stackframe.bat :GetVars _MalCode
		
@REM 		rem set call path.
@REM 		call Stackframe.bat :SaveVars G_CallPath
@REM 		set "G_CallPath=!G_CallPath! REP"

@REM 		call Stackframe.bat :SaveVars _MalCode
@REM 		call :READ
@REM 		call Stackframe.bat :GetVars _ReturnValue
		
@REM 		set "_MalCode=!_ReturnValue!"
@REM 		call Stackframe.bat :SaveVars _MalCode
@REM 		call :EVAL
@REM 		call Stackframe.bat :GetVars _ReturnValue

@REM 		set "_MalCode=!_ReturnValue!"
@REM 		call Stackframe.bat :SaveVars _MalCode
@REM 		call :PRINT

@REM 		rem restore call path.
@REM 		call Stackframe.bat :GetVars G_CallPath

@REM 		rem return, no return value.
@REM 	goto :eof
@REM ) %Speed Improve End%

@REM ---------------------------------------------------------------------------

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
	set "_Prompt=user> "
	call IO.bat :WriteVar _Prompt
	call IO.bat :ReadEscapedLine
	call Function.bat :GetRetVar _MalCode
	
	rem wrap a string.
	call Namespace.bat :New
	call Function.bat :GetRetVar _StrMalCode
	set "!_StrMalCode!.LineCount=1"
	set "!_StrMalCode!.Lines[1]=!_MalCode!"

	call Function.bat :PrepareCall _StrMalCode
	call :REP
	call Function.bat :DropRetVar

	rem free string.
	call Namespace.bat :Free !_StrMalCode!
goto :Main


%Speed Improve Start% (
	:Read
		call Function.bat :GetArgs _StrMalCode
		call Function.bat :SaveCurrentCallInfo Read

		call Function :PrepareCall _StrMalCode
		call Reader.bat :ReadString
		call Function.bat :GetRetVar _ObjMalCode

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _ObjMalCode
	goto :eof

	:Eval
		call Function.bat :GetArgs _ObjMalCode
		call Function.bat :SaveCurrentCallInfo Eval

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _ObjMalCode
	goto :eof

	:Print
		call Function.bat :GetArgs _ObjMalCode
		call Function.bat :SaveCurrentCallInfo Print
		
		call Function.bat :PrepareCall _ObjMalCode
		call Printer.bat :PrintMalType
		call Function.bat :GetRetVar _StrMalCode
		
		call Variable.bat :CopyVar !_StrMalCode!.LineCount _LineCount
		for /l %%i in (1 1 !_LineCount!) do (
			call Variable.bat :CopyVar !_StrMalCode!.Lines[%%i] _Line
			call IO.bat :WriteEscapedLineVar _Line
		)

		call Function.bat :RestoreCallInfo
		call Function.bat :RetNone
	goto :eof

	:REP
		call Function.bat :GetArgs _StrMalCode
		call Function.bat :SaveCurrentCallInfo REP

		call Function.bat :PrepareCall _StrMalCode
		call :READ
		call Function.bat :GetRetVar _ObjMalCode
		
		call Function.bat :PrepareCall _ObjMalCode
		call :EVAL
		call Function.bat :GetRetVar _ObjMalCode

		call Function.bat :PrepareCall _ObjMalCode
		call :PRINT
		call Function.bat :DropRetVar

		call Function.bat :RestoreCallInfo
		call Function.bat :RetNone
	goto :eof
) %Speed Improve End%

