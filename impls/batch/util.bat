@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			>&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		>&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:UTIL_Init Main
	if "%~1" == "" (
		>&2 echo [%~n0] Fatal: 'Main' undefined.
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
		
		set "<-=call :UTIL_SetRet"
		set "->=& call :UTIL_GetRet"
		set "|->=call !_T.UTIL! :UTIL_GetRet"
		set "??=call !_T.UTIL! :UTIL_Throw"		
		set "?|=call !_T.UTIL! :UTIL_Fatal"
		set "&=call !_T.UTIL! :UTIL_Copy"
		set "{=call !_T.UTIL! :UTIL_Invoke"
		set "}=& (if defined _G.ERR (exit /b 0))"
		set "?}=& if defined _G.ERR"
		set "?=if defined _G.ERR"
		set "-|=exit /b 0"

		if defined _G.FAST (
			set _G.SKIPTHIS=rem
			set _G.DOTHIS=
		) else (
			set _G.SKIPTHIS=
			set _G.DOTHIS=rem
		)
	) else (
		%?|% "double initialized."
	)
	
	%_G.SKIPTHIS% for /f "delims==" %%a in (
	%_G.SKIPTHIS% 	'set "_T" 2^>nul'
	%_G.SKIPTHIS% ) do set "%%a="
%-|%

:UTIL_Invoke ModName Fn ... -> ...
	%_G.SKIPTHIS% if not defined _G.UTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: UTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% )
	
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'ModName' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'Fn' undefined."
	
	%_G.SKIPTHIS% set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
	%_G.SKIPTHIS% set "_G.TRACE=!_G.TRACE!>(%~1)%~2"
	
	set /a "_G.LEVEL += 1"
	
	if defined _G.PACKED (
		if /i "%~1" == "MAIN" (
			call :MAIN_%~2 %3 %4 %5 %6 %7 %8 %9
		) else (
			call :%~1_%~2 %3 %4 %5 %6 %7 %8 %9
		)
	) else (
		if /i "%~1" == "MAIN" (
			call "%~dp0!_G.MAIN!.bat" CALL_SELF :MAIN_%~2 %3 %4 %5 %6 %7 %8 %9
		) else (
			call "%~dp0%~1.bat" :%~1_%~2 %3 %4 %5 %6 %7 %8 %9
		)
	)
	
	if defined _G.NSUTIL (
		%_G.SKIPTHIS% set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
		%_G.SKIPTHIS% set "_G.TRACE=!_G.TRACE!>(NSUTIL)Free"
		set /a "_G.LEVEL += 1"
		set /a "_T.PrevLevel = _G.LEVEL - 1"
		( set "_G.LEVEL[!_T.PrevLevel!]" ) > "%TEMP%\mal_gc_!_T.PrevLevel!.txt" 2>nul
		for /f "usebackq delims==" %%a in ("%TEMP%\mal_gc_!_T.PrevLevel!.txt") do (
			if defined _G.PACKED (
				call :NSUTIL_Free "%%a"
			) else (
				call "%~dp0NSUTIL.bat" :NSUTIL_Free "%%a"
			)
			set "%%a="
		)

		set /a "_G.LEVEL -= 1"
		%_G.SKIPTHIS% %&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
		%_G.SKIPTHIS% set "_G.TRACE[!_G.LEVEL!]="
	)
	
	( set "_L[!_G.LEVEL!]" ) > "%TEMP%\mal_l_!_G.LEVEL!.txt" 2>nul
		for /f "usebackq delims==" %%a in ("%TEMP%\mal_l_!_G.LEVEL!.txt") do set "%%a="
	
	set /a _G.LEVEL -= 1
	
	%_G.SKIPTHIS% %&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
	%_G.SKIPTHIS% set "_G.TRACE[!_G.LEVEL!]="
	
	%_G.SKIPTHIS% for /f "delims==" %%a in (
	%_G.SKIPTHIS% 	'set "_T" 2^>nul'
	%_G.SKIPTHIS% ) do set "%%a="
%-|%

:UTIL_GetRet *Var
	%_G.SKIPTHIS% if not defined _G.UTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: UTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'Var' undefined."	

	if not defined _G.ERR (
		set "%~1=!_G.RET!"
	)
	set "_G.RET="
%-|%

:UTIL_SetRet *Var
	%_G.SKIPTHIS% if not defined _G.UTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: UTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'Var' undefined."

	if defined _G.NSUTIL (
		call set "_T.Type=%%!%~1!.Type%%"
		if /i "!_T.Type!" == "NSMeta" (
			if defined _G.LEVEL[!_G.LEVEL!][!%~1!] (
				set "_G.LEVEL[!_G.LEVEL!][!%~1!]="
				set /a "_T.PrevLevel = _G.LEVEL - 1"
				set "_G.RET=!%~1!"
				set "_G.LEVEL[!_T.PrevLevel!][!_G.RET!]=!_G.RET!"
			) else (
				rem Found NS argument, just return it.
				set "_G.RET=!%~1!"
			)
		) else (
			set "_G.RET=!%~1!"
		)
	) else (
		set "_G.RET=!%~1!"
	)
%-|%

:UTIL_Throw Msg [Type]
	%_G.SKIPTHIS% if not defined _G.UTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: UTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	set "_G.ERR=_"
	if "%~2" neq "" (
		set "_G.ERR.Type=%~2"
	) else (
		set "_G.ERR.Type=Exception"
	)
	set "_G.ERR.Msg=[!_G.TRACE!] !_G.ERR.Type!: %~1"

	%_G.SKIPTHIS% for /f "delims==" %%a in (
	%_G.SKIPTHIS% 	'set "_T" 2^>nul'
	%_G.SKIPTHIS% ) do set "%%a="
%-|%

:UTIL_Copy *From *To
	%_G.SKIPTHIS% if not defined _G.UTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: UTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )
	
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'From' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'To' undefined."
	
	set "%~2=!%~1!"
%-|%

:UTIL_Fatal Msg
	%_G.SKIPTHIS% if not defined _G.UTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: UTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )
	
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'Msg' undefined."
	
	>&2 echo [!_G.TRACE!] Fatal: %~1
	2>con >&2 pause
	exit 1
%-|%
