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
	
@REM 	rem wrap a string.
@REM 	call Namespace.bat :New
@REM 	call Function.bat :GetRetVar _StrMalCode
@REM 	set "!_StrMalCode!.LineCount=1"
@REM 	set "!_StrMalCode!.Lines[1]=!_MalCode!"

@REM 	call Function.bat :PrepareCall _StrMalCode
@REM 	call :REP
@REM 	call Function.bat :DropRetVar

@REM 	rem free string.
@REM 	call Namespace.bat :Free !_StrMalCode!
@REM goto :Main


@REM %Speed Improve Start% (
@REM 	:Read
@REM 		call Function.bat :GetArgs _StrMalCode
@REM 		call Function.bat :SaveCurrentCallInfo Read

@REM 		call Function :PrepareCall _StrMalCode
@REM 		call Reader.bat :ReadString
@REM 		call Function.bat :GetRetVar _ObjMalCode

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetVar _ObjMalCode
@REM 	goto :eof

@REM 	:Eval
@REM 		call Function.bat :GetArgs _ObjMalCode
@REM 		call Function.bat :SaveCurrentCallInfo Eval

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetVar _ObjMalCode
@REM 	goto :eof

@REM 	:Print
@REM 		call Function.bat :GetArgs _ObjMalCode
@REM 		call Function.bat :SaveCurrentCallInfo Print
		
@REM 		call Function.bat :PrepareCall _ObjMalCode
@REM 		call Printer.bat :PrintMalType
@REM 		call Function.bat :GetRetVar _StrMalCode
		
@REM 		call Variable.bat :CopyVar !_StrMalCode!.LineCount _LineCount
@REM 		for /l %%i in (1 1 !_LineCount!) do (
@REM 			call Variable.bat :CopyVar !_StrMalCode!.Lines[%%i] _Line
@REM 			call IO.bat :WriteEscapedLineVar _Line
@REM 		)

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetNone
@REM 	goto :eof

@REM 	:REP
@REM 		call Function.bat :GetArgs _StrMalCode
@REM 		call Function.bat :SaveCurrentCallInfo REP

@REM 		call Function.bat :PrepareCall _StrMalCode
@REM 		call :READ
@REM 		call Function.bat :GetRetVar _ObjMalCode
		
@REM 		call Function.bat :PrepareCall _ObjMalCode
@REM 		call :EVAL
@REM 		call Function.bat :GetRetVar _ObjMalCode

@REM 		call Function.bat :PrepareCall _ObjMalCode
@REM 		call :PRINT
@REM 		call Function.bat :DropRetVar

@REM 		call Function.bat :RestoreCallInfo
@REM 		call Function.bat :RetNone
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
goto Main


:Main
	set "_Prompt=user> "
	call IO.bat :WriteVar _Prompt
	
	call IO.bat :ReadEscapedLine
	call Str.bat :New G_RET
	set "_Str=!G_RET!"
	
	call SF.bat :SaveVars _Str
	call :REP _Str
	call SF.bat :GetVars _Str
	
	call NS.bat :Free !_StrMalCode!
goto :Main

:Read _StrMalCode
	set "_StrMalCode=!%~1!"
	
	call Reader.bat :ReadString _StrMalCode
goto :eof

:Eval _ObjMalCode
	set "G_RET=!%~1!"
goto :eof

:Print _ObjMalCode
	set "_ObjMalCode=!%~1!"
	
	call Printer.bat :PrintMalType _ObjMalCode
	@REM call Function.bat :GetRetVar _StrMalCode
	
	@REM call Variable.bat :CopyVar !_StrMalCode!.LineCount _LineCount
	@REM for /l %%i in (1 1 !_LineCount!) do (
	@REM 	call Variable.bat :CopyVar !_StrMalCode!.Lines[%%i] _Line
	@REM 	call IO.bat :WriteEscapedLineVar _Line
	@REM )

	@REM call Function.bat :RestoreCallInfo
	@REM call Function.bat :RetNone
goto :eof

:REP _StrMalCode
	set "_StrMalCode=!%~1!"
	
	call :Read _StrMalCode
	call :EVAL G_RET
	call :PRINT G_RET
goto :eof