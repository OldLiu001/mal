@REM v:0.5

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
	set "!_G_RET!.Line[1]=!%~1!"
exit /b 0

:FromVal _Val
	!_C_Invoke! NS.bat :New String
	set "!_G_RET!.LineCount=1"
	set "!_G_RET!.Line[1]=%~1"
exit /b 0

:AppendStr _Str _NewStr
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! !%~1!.LineCount _L{%%.}_LineCount
		!_C_Copy! !%~2!.LineCount _L{%%.}_LineCount2
		if !_L{%%.}_LineCount! geq 1 (
			if !_L{%%.}_LineCount2! geq 1 (
				!_C_Copy! !%~1!.Line[!_L{%%.}_LineCount!] _L{%%.}_Line
				!_C_Copy! !%~2!.Line[1] _L{%%.}_Line2
				set "!%~1!.Line[!_L{%%.}_LineCount!]=!_L{%%.}_Line!!_L{%%.}_Line2!"
			)
		)
		for /l %%i in (2 1 !_L{%%.}_LineCount2!) do (
			set /a _L{%%.}_LineCount += 1
			!_C_Copy! !%~2!.Line[%%i] !%~1!.Line[!_L{%%.}_LineCount!]
		)
		!_C_Copy! _L{%%.}_LineCount !%~1!.LineCount
		set "_G_RET="
	)
exit /b 0

:AppendVal _Str _Val
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! !%~1!.LineCount _L{%%.}_LineCount
		if "!_L{%%.}_LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set _L{%%.}_LineCount=1
		)
		if defined !%~1!.Line[!_L{%%.}_LineCount!] (
			!_C_Copy! !%~1!.Line[!_L{%%.}_LineCount!] _L{%%.}_LastLine
			set "_L{%%.}_LastLine=!_L{%%.}_LastLine!%~2"
			!_C_Copy! _L{%%.}_LastLine !%~1!.Line[!_L{%%.}_LineCount!]
		) else (
			set "_L{%%.}_LastLine=%~2"
			!_C_Copy! _L{%%.}_LastLine !%~1!.Line[!_L{%%.}_LineCount!]
		)
		set "_G_RET="
	)
exit /b 0

:AppendVar _Str _Var
	for %%. in (!_G_LEVEL!) do (
		!_C_Copy! !%~1!.LineCount _L{%%.}_LineCount
		if "!_L{%%.}_LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set _L{%%.}_LineCount=1
		)
		if defined !%~1!.Line[!_L{%%.}_LineCount!] (
			!_C_Copy! !%~1!.Line[!_L{%%.}_LineCount!] _L{%%.}_LastLine
			set "_L{%%.}_LastLine=!_L{%%.}_LastLine!!%~2!"
			!_C_Copy! _L{%%.}_LastLine !%~1!.Line[!_L{%%.}_LineCount!]
		) else (
			set "_L{%%.}_LastLine=!%~2!"
			!_C_Copy! _L{%%.}_LastLine !%~1!.Line[!_L{%%.}_LineCount!]
		)
		set "_G_RET="
	)
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