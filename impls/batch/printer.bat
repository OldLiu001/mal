@REM Module Name: Printer

@rem Export Functions:
@REM 	PrintMalType

@REM Origin name mapping:
@REM 	pr_str -> PrintMalType

@REM Special Symbol Mapping:
@REM 	! --- $E
@REM 	^ --- $C
@REM 	" --- $D
@REM 	% --- $P
@REM 	$ --- $$

@rem Requirement: enable delayed expansion.

@echo off

::Start
	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=
goto :eof

(
	:PrintMalType
		call Function.bat :GetArgs _ObjMalCode
		set _ObjMalCode
		set !_ObjMalCode!
		call Function.bat :SaveCurrentCallInfo PrintMalType

		if not defined !_ObjMalCode! (
			rem TODO
			echo !_ObjMalCode! not defined!
			pause & exit
		)
		if not defined !_ObjMalCode!.Type (
			rem TODO
			echo !_ObjMalCode!.Type not defined!
			pause & exit
		)
		call :CopyVar !_ObjMalCode!.Type _Type
		if not "!_Type!" == "MalType" (
			rem TODO
			echo _ObjMalCode is not a MalType!
			pause & exit
		)
		if not defined !_ObjMalCode!.MalType (
			rem TODO
			echo !_ObjMalCode!.MalType not defined!
			pause & exit
		)
		call :CopyVar !_ObjMalCode!.MalType _MalType

		call Namespace.bat :New
		call Function.bat :GetRetVar _StrMalCode
		set "!_StrMalCode!.Type=String"
		set "!_StrMalCode!.LineCount=1"

		
		if "!_MalType!" == "Number" (
			call :CopyVar !_ObjMalCode!.Value !_StrMalCode!.Lines[1]
		) else if "!_MalType!" == "Symbol" (
			call :CopyVar !_ObjMalCode!.Value !_StrMalCode!.Lines[1]
		) else if "!_MalType!" == "List" (
			@REM TODO: Append "(" to string.
			call :CopyVar !_ObjMalCode!.Count _Count
			set !_ObjMalCode!
			for /l %%i in (1 1 !_Count!) do (
				call Stackframe.bat :SaveVars _StrMalCode _ObjMalCode
				call Variable.bat :CopyVar !_ObjMalCode!.Item[%%i] _ObjMalCode
				call Function.bat :PrepareCall _ObjMalCode
				call :PrintMalType
				call Function.bat :GetRetVar _RetStrMalCode
				call Stackframe.bat :GetVars _StrMalCode _ObjMalCode
				call :CombineStr _StrMalCode _RetStrMalCode
				call Function.bat :GetRetVar _StrMalCode
				
				@REM TODO: Append " " to string
			)
			@REM TODO: Append ")" to string
		) else (
			rem TOOD
			echo MalType !_MalType! not support yet!
			pause & exit
		)

		call Function.bat :RestoreCallInfo
		call Function.bat :RetVar _StrMalCode
	goto :eof



	:CopyVar _VarNameFrom _VarNameTo
		if not defined %~1 (
			echo [!G_CallPath!] %~1 is not defined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	goto :eof

	:CombineStr _Str1 _Str2
		if not defined %~1 (
			echo [!G_CallPath!] %~1 is not defined.
			pause & exit 1
		)
		if not defined %~2 (
			echo [!G_CallPath!] %~2 is not defined.
			pause & exit 1
		)
		call :CopyVar !%~1!.Type _Type
		if "!_Type!" Neq "String" (
			echo [!G_CallPath!] %~1 is not a string.
			pause & exit 1
		)
		call :CopyVar !%~2!.Type _Type
		if "!_Type!" Neq "String" (
			echo [!G_CallPath!] %~2 is not a string.
			pause & exit 1
		)

		call Namespace.bat :New
		call Function.bat :GetRetVar _StrRes
		set "!_StrRes!.Type=String"
		set _LineCount=0
		call Variable.bat :CopyVar !%~1!.LineCount _LineCount1
		call Variable.bat :CopyVar !%~2!.LineCount _LineCount2
		for /l %%i in (1 1 !_LineCount1!) do (
			set /a _LineCount += 1
			call Variable.bat :CopyVar !%~1!.Lines[%%i] !_StrRes!.Lines[!_LineCount!]
		)
		if !_LineCount2! geq 1 (
			call Variable.bat :CopyVar !_StrRes!.Lines[!_LineCount!] _Line
			call Variable.bat :CopyVar !%~2!.Lines[1] _Line2
			set "_Line=!_Line!!_Line2!"
			call Variable.bat :CopyVar _Line !_StrRes!.Lines[!_LineCount!]
		)
		for /l %%i in (2 1 !_LineCount2!) do (
			set /a _LineCount += 1
			call Variable.bat :CopyVar !%~2!.Lines[%%i] !_StrRes!.Lines[!_LineCount!]
		)
		call Variable.bat :CopyVar _LineCount !_StrRes!.LineCount
		call Function.bat :RetVar _StrRes
	goto :eof
)