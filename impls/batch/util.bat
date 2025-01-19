@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			2>con >&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		2>con >&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:UTIL_Init Main
	if "%~1" == "" (
		2>con >&2 echo [%~n0] Fatal: 'Main' undefined.
		2>con >&2 pause
		exit 1
	)
	
	if not defined _G.UTIL (
		set "_G.UTIL=%~n0"
		set "_G.MAIN=%~1"
		set "_G.TRACE=!_G.MAIN!"
		set /a "_G.LEVEL = 0
		set "_G.RET="
		set "_G.ERR="
		
		set "_T.UTIL="
		if not defined _G.PACKED set "_T.UTIL=!_G.UTIL!"
		
		set "<-=call !_T.UTIL! :UTIL_SetRet"
		set "->=& call !_T.UTIL! :UTIL_GetRet"
		set "|->=call !_T.UTIL! :UTIL_GetRet"
		set "??=call !_T.UTIL! :UTIL_Throw"		
		set "?|=call !_T.UTIL! :UTIL_Fatal"
		set "&=call !_T.UTIL! :UTIL_Copy"
		set "{=call !_T.UTIL! :UTIL_Invoke"
		set "}=& (if defined _G.ERR (exit /b 0))"
		set "?}=& if defined _G.ERR"
		set "?=if defined _G.ERR"
		set "-|=exit /b 0"
	) else (
		%?|% "double initialized."
	)
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Invoke ModName Fn ... -> ...
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
	)
	
	if "%~1" == "" %?|% "'ModName' undefined."
	if "%~2" == "" %?|% "'Fn' undefined."
	
	set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
	set "_G.TRACE=!_G.TRACE!>(%~1)%~2"
	
	set /a "_G.LEVEL += 1"
	
	for /f "tokens=1,2,*" %%a in ('echo.%*') do (
		if defined _G.PACKED (
			if /i "%%a" == "MAIN" (
				call :MAIN_%%b %%c
			) else (
				call :%%a_%%b %%c
			)
		) else (
			if /i "%%a" == "MAIN" (
				call !_G.MAIN! CALL_SELF :MAIN_%%b %%c
			) else (
				call %%a :%%a_%%b %%c
			)
		)
	)
	
	if defined _G.NSUTIL (
		set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
		set "_G.TRACE=!_G.TRACE!>(NSUTIL)Free"
		set /a "_G.LEVEL += 1"
		set /a "_T.PrevLevel = _G.LEVEL - 1"

		for /f "delims==" %%a in (
			'set "_G.LEVEL[!_T.PrevLevel!]" 2^>nul'
		) do (
			if defined _G.PACKED (
				call :NSUTIL_Free "%%a"
			) else (
				call NSUTIL :NSUTIL_Free "%%a"
			)
			set "%%a="
		)

		for /f "delims==" %%a in (
			'set "_L[!_G.LEVEL!]" 2^>nul'
		) do set "%%a="

		set /a "_G.LEVEL -= 1"
		%&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
		set "_G.TRACE[!_G.LEVEL!]="
	)
	
	for /f "delims==" %%a in (
		'set "_L[!_G.LEVEL!]" 2^>nul'
	) do set "%%a="
	
	set /a _G.LEVEL -= 1
	
	%&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
	set "_G.TRACE[!_G.LEVEL!]="
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_GetRet *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)

	if "%~1" == "" %?|% "'Var' undefined."	

	if not defined _G.ERR (
		%&% "_G.RET" "%~1"
	)
	set "_G.RET="

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_SetRet *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)

	if "%~1" == "" %?|% "'Var' undefined."

	if defined _G.NSUTIL (
		%&% "!%~1!.Type" "_T.Type"
		if /i "!_T.Type!" == "NSMeta" (
			%{% NSUTIL CloneMeta "%~1" "_G.RET" %}%

			set /a "_T.PrevLevel = _G.LEVEL - 1"
			set "_G.LEVEL[!_T.PrevLevel!][!_G.RET!]=!_G.RET!"
		) else (
			set "_G.RET=!%~1!"
		)
	) else (
		set "_G.RET=!%~1!"
	)


	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Throw *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'Var' undefined."

	%?|% TODO: Add NS logic.
	set "_G.ERR=!%~1!"

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Copy *From *To
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'From' undefined."
	if "%~2" == "" %?|% "'To' undefined."
	
	set "%~2=!%~1!"
%-|%

:UTIL_Fatal Msg
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'Msg' undefined."
	
	2>con >&2 echo [!_G.TRACE!] Fatal: %~1
	2>con >&2 pause
	exit 1
%-|%
