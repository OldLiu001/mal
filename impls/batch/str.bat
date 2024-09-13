@REM v:1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:New -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=0"
		!_C_Return! %%.Str
	)
exit /b 0

:FromVar _Var -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=!%~1!"
		!_C_Return! %%.Str
	)
exit /b 0

:FromVal _Val -> _Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Invoke! NS.bat :New String & !_C_GetRet! %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=%~1"
		!_C_Return! %%.Str
	)
exit /b 0

:AppendStr _Str _NewStr -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		!_C_Copy! !%~2!.LineCount %%.LineCount2
		if !%%.LineCount! geq 1 (
			if !%%.LineCount2! geq 1 (
				!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.Line
				!_C_Copy! !%~2!.Line[1] %%.Line2
				set "!%~1!.Line[!%%.LineCount!]=!%%.Line!!%%.Line2!"
			)
		)
		for /l %%i in (2 1 !%%.LineCount2!) do (
			set /a %%.LineCount += 1
			!_C_Copy! !%~2!.Line[%%i] !%~1!.Line[!%%.LineCount!]
		)
		!_C_Copy! %%.LineCount !%~1!.LineCount
		!_C_Return! _
	)
exit /b 0

:AppendVal _Str _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!%~2"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=%~2"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		!_C_Return! _
	)
exit /b 0

:AppendVar _Str _Var -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		!_C_Copy! !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			!_C_Copy! !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!!%~2!"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=!%~2!"
			!_C_Copy! %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		!_C_Return! _
	)
exit /b 0