@echo off
::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
exit /b 0


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
	!_C_Copy! !_ObjMalCode!.Type _Type
	if not "!_Type:~,3!" == "Mal" (
		rem TODO
		echo _ObjMalCode is not a MalType!
		pause & exit
	)
	
	!_C_Invoke! Str.bat :New
	!_C_Copy! _G_RET _StrMalCode
	
	if "!_Type!" == "MalNum" (
		!_C_Invoke! Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalSym" (
		!_C_Invoke! Str.bat :AppendVar _StrMalCode !_ObjMalCode!.Value
	) else if "!_Type!" == "MalLst" (
		!_C_Invoke! Str.bat :AppendVal _StrMalCode "("
		!_C_Copy! !_ObjMalCode!.Count _Count
		for /l %%i in (1 1 !_Count!) do (
			!_C_Invoke! :PrintMalType !_ObjMalCode!.Item[%%i]
			set "_RetStrMalCode=!_G_RET!"
			!_C_Invoke! Str.bat :AppendStr _StrMalCode _RetStrMalCode
			
			if "%%i" == "!_Count!" (
				!_C_Invoke! Str.bat :AppendVal _StrMalCode ")"
			) else (
				!_C_Invoke! Str.bat :AppendVal _StrMalCode " "
			)
		)
	) else (
		rem TOOD
		echo MalType !_Type! not support yet!
		pause & exit
	)

	set "_G_RET=!_StrMalCode!"
	call :ClearLocalVars
exit /b 0

(
	@REM Version 0.5
	:Invoke
		if not defined _G_TRACE (
			set "_G_TRACE=>"
		)

		set "_G_TRACE_{!_G_LEVEL!}=!_G_TRACE!"
		
		set "_G_TMP=%~1"
		if /i "!_G_TMP:~,1!" Equ ":" (
			set "_G_TRACE=!_G_TRACE!>%~1"
		) else (
			set "_G_TRACE=!_G_TRACE!>%~1>%~2"
		)
		set "_G_TMP="
		
		set /a _G_LEVEL += 1
		call %*
		set /a _G_LEVEL -= 1
		
		!_C_Copy! _G_TRACE_{!_G_LEVEL!} _G_TRACE
		set "_G_TRACE_{!_G_LEVEL!}="
	exit /b 0

	:CopyVar _VarFrom _VarTo
		if not defined %~1 (
			2>&1 echo [!_G_TRACE!] '%~1' undefined.
			pause & exit 1
		)
		set "%~2=!%~1!"
	exit /b 0
	
	:ClearLocalVars
		for /f "delims==" %%a in (
			'set _L{!_G_LEVEL!}_ 2^>nul'
		) do set "%%a="
	exit /b 0
)
