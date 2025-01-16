@echo off
if "%~1" neq "" (
	2>nul call %* || (
		if defined _G.TRACE (
			>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			>&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		>&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		>&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	>&2 pause
	exit 1
)
exit /b 0

:UTIL_Init _Main
	if "%~1" == "" (
		>&2 echo [%~n0] Fatal: _Main undefined.
		>&2 pause
		exit 1
	)
	if defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL already initialized.
		>&2 pause
		exit 1
	) else (
		set "_G.UTIL=%~n0"
		set "_G.MAIN=%~1"
		set "_G.TRACE=!_G.MAIN!"
		set /a _G.LEVEL = _G.NS = 0
		set "_G.RET="
		set "_G.ERR="
	)
%-|%

:UTIL_Invoke _ModName _Fn * -> *
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "_ModName undefined."
	if "%~2" == "" %?|% "_Fn undefined."
	
	set "_G.TRACE.!_G.LEVEL!=!_G.TRACE!"
	set "_G.TRACE=!_G.TRACE!>(%~1)%~2"
	set "_G.RET="
	set /a _G.LEVEL += 1
	
	%?|% "TODO: Add MAIN support."
	for /f "tokens=1,2,*" %%a in ('echo.%*') do (
		if defined _G.PACKED (
			call :%%a_%%b %%c
		) else (
			call %%a :%%a_%%b %%c
		)
	)
	
	for /f "delims==" %%a in (
		'set _G.LEVEL.!_G.LEVEL!.NS 2^>nul'
	) do (
		call :UTIL_Invoke !_G.UTIL! Free %%a
	)
	
	for /f "delims==" %%a in (
		'set _L.!_G.LEVEL! 2^>nul'
	) do set "%%a="
	
	set /a _G_LEVEL -= 1
	
	%&% _G.TRACE.!_G.LEVEL! _G.TRACE
	set "_G.TRACE.!_G.LEVEL!="
%-|%

:UTIL_GetRet *Var
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	if not defined _G.ERR (
		%&% _G.RET %~1
	)
	set _G.RET=
%-|%

:UTIL_SetRet Var
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	set "_G.RET="
	if "%~1" == "" %?|% "Var undefined."
	if not defined %~1.NSMARK (
		set "_G.RET=!%~1!"
	) else (
		%&% %~1 _G.RET
	)
%-|%

:UTIL_Fatal _Msg
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	>&2 echo [!_G.TRACE!] Fatal: %~1
	>&2 pause
	exit 1
%-|%

:UTIL_Throw _Msg [_Type] [Data]
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "_Msg undefined."
	
	set "_G.ERR=_"
	if "%~2" == "" (
		set "_G.ERR.Type=Exception"
	) else (
		set "_G.ERR.Type=%~2"
	)
	set "_G.ERR.Msg=[!_G.TRACE!] !_G.ERR.Type!: %~1"
	set "_G.ERR.Data="
	if "%~3" neq "" %&% %~3 _G.ERR.Data
%-|%

:UTIL_Copy From *To
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "From undefined."
	if "%~2" == "" %?|% "To undefined."
	
	if not defined %~1.NSMARK (
		set "%~2=!%~1!"
	) else (
		set /a _G.NS += 1
		set /a _G.NS.!_G.NS!.Target = %~1.Target
		set /a !%~1.Target!.RefCnt += 1
		set "%~2=_G.NS.!_G.NS!"
	)
%-|%

:UTIL_New *NS
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "NS undefined."
	
	set /a _G.NS += 1
	set "_G.NS.!_G.NS!.NSBODYMARK=1"
	set "_G.NS.!_G.NS!.RefCnt=1"
	set "_G.NS.!_G.NS!.LnkCnt=0"
	
	set /a _G.NS += 1
	set "_G.NS.!_G.NS!.NSMARK=1"
	set /a _G.NS.!_G.NS!.Target = _G.NS - 1
	set _G.LEVEL.!_G.LEVEL!.NS.!_G.NS!=_G.NS.!_G.NS!
	
	set "%~1=_G.NS.!_G.NS!"
%-|%

:UTIL_Set *NS Field Val
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "NS undefined."
	if "%~2" == "" %?|% "Field undefined."
	if "%~3" == "" %?|% "Val undefined."
	
	if not defined !%~1!.NSMARK %?|% "Invalid NS."
	%&% !%~1!.Target _T.NSBody
	if not defined !_T.NSBody!.NSBODYMARK %?|% "Invalid NSBODY."
	
	%&% !_T.NSBody!.RefCnt _T.RefCnt
	if "!_T.RefCnt!" == "1" (
		%&% %~3 !_T.NSBody!.Data.%~2
	) else (
		rem recursive copy
		%?|% TODO
	)
	
	for /f "delims==" %%a in (
		'set _T 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Get *NS Field *Val
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
		%?|% TODO
%-|%

:UTIL_Free *NS
	if not defined _G_UTIL (
		>&2 echo [%~n0] Fatal: UTIL not initialized.
		>&2 pause
		exit 1
	)
		%?|% TODO
%-|%