@REM v:0.4, untested

@REM Module Name: String

@rem Export Functions:
@rem 	:New
@rem 	:FromVar _Var
@rem 	:FromVal _Val
@rem 	:AppendStr _Str _NewStr
@rem 	:AppendVal _Str _Val
@rem 	:AppendVar _Str _Var

@echo off
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0

:New
	!_C_Invoke! NS.bat :New String
	set "!_G_RET!.LineCount=0"
exit /b 0

:FromVar _Var
	!_C_Invoke! NS.bat :New String
	set "!_G_RET!.LineCount=1"
	set "!_G_RET!.Lines[1]=!%~1!"
	!_C_Clear!
exit /b 0

:FromVal _Val
	!_C_Invoke! NS.bat :New String
	set "!_G_RET!.LineCount=1"
	set "!_G_RET!.Lines[1]=%~1"
	!_C_Clear!
exit /b 0

:AppendStr _Str _NewStr
	!_C_Copy! !%~1!.LineCount _L{!_G_LEVEL!}_LineCount
	!_C_Copy! !%~2!.LineCount _L{!_G_LEVEL!}_LineCount2
	for /f "delims=" %%a in ("_L{!_G_LEVEL!}_LineCount") do (
		if !%%a! geq 1 (
			for /f "tokens=1,2" %%b in (
				"!%~1!.Lines[!%%a!] !%~2!.Lines[1]"
			) do (
				set "!%%~b!=!%%~b!!%%~c!"
			)
		)
	)
	for /f "delims=" %%a in ("_L{!_G_LEVEL!}_LineCount2") do (
		for /l %%i in (2 1 !%%a!) do (
			for /f "delims=" %%b in ("_L{!_G_LEVEL!}_LineCount") do (
				set /a %%~b += 1
				!_C_Copy! !%~2!.Lines[%%i] !%~1!.Lines[!%%~b!]
			)
		)
	)
	!_C_Copy! _L{!_G_LEVEL!}_LineCount !%~1!.LineCount
	set "_G_RET="
	!_C_Clear!
exit /b 0

:AppendVal _Str _Val
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! !%~1!.LineCount _L{%%.}_LineCount
		if "!_L{%%.}_LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set _L{%%.}_LineCount=1
		)
		!_C_Copy! !%~1!.Lines[!_L{%%.}_LineCount!] _L{%%.}_LastLine
		set "_L{%%.}_LastLine=!_L{%%.}_LastLine!%~2"
		!_C_Copy! _L{%%.}_LastLine !%~1!.Lines[!_L{%%.}_LineCount!]
		set "_G_RET="
		!_C_Clear!
	)
exit /b 0

:AppendVar _Str _Var
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! !%~1!.LineCount _L{%%.}_LineCount
		if "!_L{%%.}_LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set _L{%%.}_LineCount=1
		)
		!_C_Copy! !%~1!.Lines[!_L{%%.}_LineCount!] _L{%%.}_LastLine
		set "_L{%%.}_LastLine=!_L{%%.}_LastLine!!%~2!"
		!_C_Copy! _L{%%.}_LastLine !%~1!.Lines[!_L{%%.}_LineCount!]
		set "_G_RET="
		!_C_Clear!
	)
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
