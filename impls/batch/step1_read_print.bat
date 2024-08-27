@REM v:0.4, untested

@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
set "_G_LEVEL=0"
set "_C_Invoke=call :Invoke"
set "_C_Copy=call :CopyVar"
set "_C_Clear=call :ClearLocalVars"

!_C_Invoke! :Main
exit /b 0

:Main
	set "_L{!_G_LEVEL!}_Prompt=user> "
	!_C_Invoke! IO.bat :WriteVar _L{!_G_LEVEL!}_Prompt
	!_C_Invoke! IO.bat :ReadEscapedLine
	set "_L{!_G_LEVEL!}_Input=!_G_RET!"
	
	!_C_Invoke! Str.bat :FromVar _L{!_G_LEVEL!}_Input
	set "_L{!_G_LEVEL!}_Str=!G_RET!"
	
	set _
	pause

	!_C_Invoke! :REP _L{!_G_LEVEL!}_Str
	
	!_C_Invoke! NS.bat :Free _L{!_G_LEVEL!}_Str

	set "G_RET="
	!_C_Clear!
goto :Main

:Read _StrMalCode
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_StrMalCode=!%~1!"
		
		!_C_Invoke! Reader.bat :ReadString _L{%%.}_StrMalCode
		set "_L{%%.}_ObjMalCode=!G_RET!"

		set "G_RET=!_L{%%.}_ObjMalCode!"
		!_C_Clear!
	)
exit /b 0

:Eval _MalCode
	set "_L{!_G_LEVEL!}_MalCode=!%~1!"

	!_C_Copy! _L{!_G_LEVEL!}_MalCode _G_RET
	!_C_Clear!
exit /b 0

:Print _ObjMalCode
	for %%. in (!_G_LEVEL!) do (
		set "_L{%%.}_ObjMalCode=!%~1!"
		
		!_C_Invoke! Printer.bat :PrintMalType _L{%%.}_ObjMalCode
		set "_L{%%.}_StrMalCode=!G_RET!"

		!_C_Invoke! IO.bat :WriteStr _L{%%.}_StrMalCode

		!_C_Clear!
	)
exit /b 0

:REP _MalCode
	set "_L{!_G_LEVEL!}_MalCode=!%~1!"
	
	!_C_Invoke! :Read _L{!_G_LEVEL!}_MalCode
	!_C_Copy! _G_RET _L{!_G_LEVEL!}_MalCode
	!_C_Invoke! :Eval _L{!_G_LEVEL!}_MalCode
	!_C_Copy! _G_RET _L{!_G_LEVEL!}_MalCode
	!_C_Invoke! :Print _L{!_G_LEVEL!}_MalCode

	!_C_Clear!
exit /b 0

(
	@REM Version 0.4
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
		set "_G_TRACE_{!_G_LEVEL}="
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

