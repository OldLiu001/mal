@REM v0.5
@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0


:PrintMalType _ObjMalCode
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ObjMalCode=!%~1!"

		if not defined !_L{%%.}_ObjMalCode! (
			rem TODO
			echo !_L{%%.}_ObjMalCode! not defined!
			pause & exit
		)
		if not defined !_L{%%.}_ObjMalCode!.Type (
			rem TODO
			echo !_L{%%.}_ObjMalCode!.Type not defined!
			pause & exit
		)
		!_C_Copy! !_L{%%.}_ObjMalCode!.Type _L{%%.}_Type
		if not "!_L{%%.}_Type:~,3!" == "Mal" (
			rem TODO
			echo _L{%%.}_ObjMalCode is not a MalType!
			pause & exit
		)
		
		!_C_Invoke! Str.bat :New
		!_C_Copy! _G_RET _L{%%.}_StrMalCode
		
		if "!_L{%%.}_Type!" == "MalNum" (
			!_C_Invoke! Str.bat :AppendVar _L{%%.}_StrMalCode !_L{%%.}_ObjMalCode!.Value
		) else if "!_L{%%.}_Type!" == "MalSym" (
			!_C_Invoke! Str.bat :AppendVar _L{%%.}_StrMalCode !_L{%%.}_ObjMalCode!.Value
		) else if "!_L{%%.}_Type!" == "MalNil" (
			!_C_Invoke! Str.bat :AppendVar _L{%%.}_StrMalCode !_L{%%.}_ObjMalCode!.Value
		) else if "!_L{%%.}_Type!" == "MalBool" (
			!_C_Invoke! Str.bat :AppendVar _L{%%.}_StrMalCode !_L{%%.}_ObjMalCode!.Value
		) else if "!_L{%%.}_Type!" == "MalStr" (
			!_C_Invoke! Str.bat :AppendVar _L{%%.}_StrMalCode !_L{%%.}_ObjMalCode!.Value
		) else if "!_L{%%.}_Type!" == "MalLst" (
			!_C_Invoke! Str.bat :AppendVal _L{%%.}_StrMalCode "("
			!_C_Copy! !_L{%%.}_ObjMalCode!.Count _L{%%.}_Count
			for /l %%i in (1 1 !_L{%%.}_Count!) do (
				!_C_Invoke! :PrintMalType !_L{%%.}_ObjMalCode!.Item[%%i]
				!_C_Copy! _G_RET _L{%%.}_RetStrMalCode
				!_C_Invoke! Str.bat :AppendStr _L{%%.}_StrMalCode _L{%%.}_RetStrMalCode
				!_C_Invoke! NS.bat :Free _L{%%.}_RetStrMalCode
				
				if  "%%i" neq "!_L{%%.}_Count!" (
					!_C_Invoke! Str.bat :AppendVal _L{%%.}_StrMalCode " "
				)
			)
			!_C_Invoke! Str.bat :AppendVal _L{%%.}_StrMalCode ")"
		) else (
			rem TOOD
			echo MalType !_L{%%.}_Type! not support yet!
			pause & exit
		)
		!_C_Invoke! NS.bat :Free _L{%%.}_ObjMalCode

		set "_G_RET=!_L{%%.}_StrMalCode!"
		call :ClearLocalVars
	)
exit /b 0

(
	@REM Version 0.7
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
		
		set "_G_RET="
		set /a _G_LEVEL += 1
		call %*
		call :ClearLocalVars
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