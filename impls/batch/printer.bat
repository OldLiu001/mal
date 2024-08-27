@echo off
::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
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
	set !_ObjMalCode!.Type
	echo 1t
	set _Type
	if not "!_Type:~,3!" == "Mal" (
		rem TODO
		echo _ObjMalCode is not a MalType!
		pause & exit
	)
	
	call :Invoke Str.bat :New
	call :CopyVar G_RET _StrMalCode
	
	if "!_Type!" == "MalNum" (
		call :Invoke Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalSym" (
		call :Invoke Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalLst" (
		echo mallst
		call :Invoke Str.bat :AppendVal _StrMalCode "("
		call :CopyVar !_ObjMalCode!.Count _Count
		for /l %%i in (1 1 !_Count!) do (
			call :Invoke :PrintMalType !_ObjMalCode!.Item[%%i]
			set "_RetStrMalCode=!G_RET!"
			call :Invoke Str.bat :AppendStr _StrMalCode _RetStrMalCode
			
			if "%%i" == "!_Count!" (
				call :Invoke Str.bat :AppendVal _StrMalCode ")"
			) else (
				call :Invoke Str.bat :AppendVal _StrMalCode " "
			)
		)
		echo FINISH
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

:Invoke
	call SF.Bat :SaveLocalVars
	call %*
	call SF.Bat :RestoreLocalVars
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof

:CopyVar _VarFrom _VarTo
	set "%~2=!%~1!"
goto :eof
