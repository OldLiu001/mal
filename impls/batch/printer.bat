@echo off

::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:CopyVar _VarFrom _VarTo
	if not defined %~1 (
		>&2 echo %~1 is not defined.
		pause & exit 1
	)
	set "%~2=!%~1!"
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof

:PrintMalType _ObjMalCode
	set "_ObjMalCode=!%~1!"

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
	if not "!_Type:~,3!" == "Mal" (
		rem TODO
		echo _ObjMalCode is not a MalType!
		pause & exit
	)
	
	call SF.bat :SaveLocalVars
	call Str.bat :New
	call SF.bat :RestoreLocalVars
	call :CopyVar G_RET _StrMalCode
			set _ObjMalCode
			set !_ObjMalCode!

			echo aaa
	if "!_Type!" == "MalNum" (
		call Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalSym" (
		call Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalLst" (
			echo ab
	call SF.bat :SaveLocalVars
		call Str.bat :AppendVal _StrMalCode "("
	call SF.bat :RestoreLocalVars
			echo ac
			set _ObjMalCode
			set !_ObjMalCode!
		call :CopyVar !_ObjMalCode!.Count _Count
			echo ad
		for /l %%i in (1 1 !_Count!) do (
			echo a
			call SF.bat :SaveLocalVars
			call :PrintMalType !_ObjMalCode!.Item[%%i]
			call :CopyVar G_RET _RetStrMalCode
			call SF.bat :RestoreLocalVars
	call SF.bat :SaveLocalVars
			call Str.bat :AppendStr _StrMalCode _RetStrMalCode
			echo b	
			if "%%i" == "!_Count!" (
				call Str.bat :AppendVal _StrMalCode ")"
			) else (
				call Str.bat :AppendVal _StrMalCode " "
			)
		set !_StrMalCode!
	call SF.bat :RestoreLocalVars
		)
	) else (
		rem TOOD
		echo MalType !_Type! not support yet!
		set !_ObjMalCode!
		pause & exit
	)

	set "G_RET=!_StrMalCode!"
	echo return
	set G_RET
	set !G_RET!
	call :ClearLocalVars
goto :eof

