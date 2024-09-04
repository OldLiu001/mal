@REM v0.5

@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
set "_G_LEVEL=0"
set "_C_Invoke=call :Invoke"
set "_C_Copy=call :CopyVar"
!_C_Invoke! :Main
exit /b 0


:Main
	set "_L{!_G_LEVEL!}_Prompt=user> "
	!_C_Invoke! IO.bat :WriteVar _L{!_G_LEVEL!}_Prompt
	!_C_Invoke! IO.bat :ReadEscapedLine
	set "_L{!_G_LEVEL!}_Input=!_G_RET!"
	!_C_Invoke! :REP _L{!_G_LEVEL!}_Input
	set "_G_RET="
goto :Main

:Read _MalCode
	set "_L{!_G_LEVEL!}_MalCode=!%~1!"

	!_C_Copy! _L{!_G_LEVEL!}_MalCode _G_RET
exit /b 0

:Eval _MalCode
	set "_L{!_G_LEVEL!}_MalCode=!%~1!"

	!_C_Copy! _L{!_G_LEVEL!}_MalCode _G_RET
exit /b 0

:Print _MalCode
	set "_L{!_G_LEVEL!}_MalCode=!%~1!"

	!_C_Invoke! IO.bat :WriteEscapedLineVar _L{!_G_LEVEL!}_MalCode

	!_C_Copy! _L{!_G_LEVEL!}_MalCode _G_RET
exit /b 0

:REP _MalCode
	set "_L{!_G_LEVEL!}_MalCode=!%~1!"
	
	!_C_Invoke! :Read _L{!_G_LEVEL!}_MalCode
	!_C_Copy! _G_RET _L{!_G_LEVEL!}_MalCode
	!_C_Invoke! :Eval _L{!_G_LEVEL!}_MalCode
	!_C_Copy! _G_RET _L{!_G_LEVEL!}_MalCode
	!_C_Invoke! :Print _L{!_G_LEVEL!}_MalCode

exit /b 0

(
	@REM Version 0.8
	:Invoke
		set /a _G_LEVEL = _G_LEVEL
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
		
		for /f "delims==" %%a in (
			'set _L{!_G_LEVEL!}_ 2^>nul'
		) do set "%%a="

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
)