@REM v:1.4

@echo off & pushd "%~dp0" & setlocal ENABLEDELAYEDEXPANSION
call :Init
!_C_Invoke! :Main
exit /b 0

:Main
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Prompt=user> " & !_C_Invoke! IO.bat :WriteVar %%.Prompt
		!_C_Invoke! IO.bat :ReadEscapedLine
		if defined _G_RET (
			!_C_GetRet! %%.Input
		) else (
			goto :Main
		)
		
		!_C_Invoke! Str.bat :FromVar %%.Input & !_C_GetRet! %%.Str

		!_C_Invoke! :REP %%.Str
		if defined _G_ERR (
			if "!_G_ERR.Type!" == "Exception" (
				!_C_Invoke! IO.bat :WriteErrLineVar _G_ERR.Msg
			) else if "!_G_ERR.Type!" == "Empty" (
				rem do nothing.
			) else (
				!_C_Fatal! "Error type '!_G_ERR.Type!' not support."
			)

			for /f "delims==" %%a in (
				'set _G_ERR 2^>nul'
			) do set "%%a="
		)
		
		!_C_Invoke! NS.bat :Free %%.Str
	)
goto :Main

:Read _StrMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.StrMal=!%~1!"
		
		!_C_Invoke! Reader.bat :ReadString %%.StrMal & !_C_GetRet! %%.ObjMal
		if defined _G_ERR exit /b 0

		!_C_Return! %%.ObjMal
	)
exit /b 0

:Eval _ObjMal -> _ObjMal
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		!_C_Return! %%.ObjMal
	)
exit /b 0

:Print _ObjMal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.ObjMal=!%~1!"
		
		!_C_Invoke! Printer.bat :PrintMalType %%.ObjMal & !_C_GetRet! %%.StrMal
		
		!_C_Invoke! IO.bat :WriteStr %%.StrMal

		!_C_Invoke! NS.bat :Free %%.StrMal

		!_C_Return! _
	)
exit /b 0

:REP _Mal -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Mal=!%~1!"
		
		!_C_Invoke! :Read %%.Mal & !_C_GetRet! %%.Mal
		if defined _G_ERR exit /b 0
		!_C_Invoke! :Eval %%.Mal & !_C_GetRet! %%.Mal
		!_C_Invoke! :Print %%.Mal
		!_C_Return! _
	)
exit /b 0