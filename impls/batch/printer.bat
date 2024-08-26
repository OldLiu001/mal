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
		call Function.bat :GetVars _ObjMalCode
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
		
		
		if "!_MalType!" == "Number" (

		) else if "!_MalType!" == "Symbol" (

		) else if "!_MalType!" == "List" (

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
)