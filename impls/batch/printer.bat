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
	if not "!_Type:~,3!" == "Mal" (
		rem TODO
		echo _ObjMalCode is not a MalType!
		pause & exit
	)
	
	!C_Invoke! Str.bat :New
	call :CopyVar G_RET _StrMalCode
	
	if "!_Type!" == "MalNum" (
		!C_Invoke! Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalSym" (
		!C_Invoke! Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalLst" (
		!C_Invoke! Str.bat :AppendVal _StrMalCode "("
		call :CopyVar !_ObjMalCode!.Count _Count
		for /l %%i in (1 1 !_Count!) do (
			!C_Invoke! :PrintMalType !_ObjMalCode!.Item[%%i]
			set "_RetStrMalCode=!G_RET!"
			!C_Invoke! Str.bat :AppendStr _StrMalCode _RetStrMalCode
			
			if "%%i" == "!_Count!" (
				!C_Invoke! Str.bat :AppendVal _StrMalCode ")"
			) else (
				!C_Invoke! Str.bat :AppendVal _StrMalCode " "
			)
		)
	) else (
		rem TOOD
		echo MalType !_Type! not support yet!
		pause & exit
	)

	set "G_RET=!_StrMalCode!"
	call :ClearLocalVars
goto :eof

(
	:Invoke
		if not defined G_TRACE (
			set "G_TRACE=MAIN"
		)
		call SF.Bat :PushVar G_TRACE
		set "G_TMP=%~1"
		if /i "!G_TMP:~,1!" Equ ":" (
			set "G_TRACE=!G_TRACE!>%~1"
		) else (
			set "G_TRACE=!G_TRACE!>%~1>%~2"
		)
		set "G_TMP="
		call SF.Bat :SaveLocalVars
		call %*
		call SF.Bat :RestoreLocalVars
		call SF.Bat :PopVar G_TRACE
	goto :eof

	:ClearLocalVars
		for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
	goto :eof

	:CopyVar _VarFrom _VarTo
		if not defined %~1 (
			2>&1 echo [!G_TRACE!] %~1 is not defined.
		)
		set "%~2=!%~1!"
	goto :eof
)