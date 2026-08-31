@echo off
setlocal ENABLEDELAYEDEXPANSION
set _G.PACKED=1

if "%~1" equ "CALL_READLINE" call :READLINE & exit /b 0
if "%~1" equ "CALL_WRITEALL"  call :WRITEALL & exit /b 0
if "%~1" equ "CALL_SELF"      shift & goto :ENTRY_CALLER
set _G.FAST=1
call :NSUTIL_Init %~n0
call :MAIN_Main
exit /b 0

:ENTRY_CALLER
call %1
exit /b 0

@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	call %2 %3 %4 %5 %6 %7 %8 %9 || %?|% "Call '%~nx0' failed."
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)

%{% MAIN Main %}%
%-|%

:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Prompt=user> "
	)
	:MAIN_REPL_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% IO WriteVar %%.Prompt %}%
		%{% IO ReadEncLine %}% %->% %%.Input
		if defined %%.Input (
			call !_T.UTIL! :UTIL_Invoke MAIN REP %%.Input
			%?% (
				if "!_G.ERR.Type!" == "Exception" (
					call !_T.UTIL! :UTIL_Invoke IO WriteErrLineVar _G.ERR.Msg
				) else if "!_G.ERR.Type!" == "Empty" (
					rem do nothing.
				) else (
					%?|% "Error type '!_G.ERR.Type!' not support."
				)

				( set _G.ERR ) > "%TEMP%\mal_e_!_G.LEVEL!.txt" 2>nul
				for /f "usebackq delims==" %%a in ("%TEMP%\mal_e_!_G.LEVEL!.txt") do set "%%a="
			)
		) else (
			exit /b 0
		)
	)
	goto MAIN_REPL_Loop
%-|%

:MAIN_Read Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% READER ReadString "!%%.Str!" %}% %->% %%.Mal
		%?% %-|%
		%<-% %%.Mal
	)
%-|%

:MAIN_Eval Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Print Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%{% PRINTER PrintMalType "%%.Mal" %}% %->% %%.StrMal
		%?% (
			%-|%
		)
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		%?% (
			%-|%
		)
		%{% IO WriteEncLine %%.Result %}%
		%<-% %%.Result
	)
%-|%

:MAIN_REP Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% MAIN Read "%%.Str" %}% %->% %%.Mal
		%?% (
			%-|%
		)
		%{% MAIN Eval %%.Mal %}% %->% %%.Mal2
		%?% (
			%-|%
		)
		%{% MAIN Print %%.Mal2 %}%
	)
%-|%

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
			call !_G.MAIN! CALL_SELF :MAIN_%~2 %3 %4 %5 %6 %7 %8 %9
		) else (
			call %~1 :%~1_%~2 %3 %4 %5 %6 %7 %8 %9
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
				call :NSUTIL_Free "%%a"
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

:NSUTIL_Init Main
	if not defined _G.NSUTIL (
		if defined _G.PACKED (
			call :UTIL_Init "%~1"
		) else (
			call :UTIL_Init "%~1"
		)

		set "_G.NSUTIL=%~n0"

		set /a "_G.NSP = 0"

			rem Env scale dynamically bounded (readme sect0 rule4): default threshold overridable via external set _G.NSMAX=...
			rem Adapt to different machines; terminate on exceed to prevent env bloat from breaking perf/stability.
		if not defined _G.NSMAX set /a "_G.NSMAX = 8000"

		if defined _G.PACKED (
			set "{n=call :NSUTIL_New"
			set "{c=call :NSUTIL_Clone"
			set "{g=call :NSUTIL_Get"
			set "{s=call :NSUTIL_Set"
		) else (
			set "{n=call :NSUTIL_New"
			set "{c=call :NSUTIL_Clone"
			set "{g=call :NSUTIL_Get"
			set "{s=call :NSUTIL_Set"
		)
	)
%-|%

:NSUTIL_New *NSVar
		rem Deprecated .for-var domain: explicit unique `_T.NW.` prefix, no longer rely on process isolation within file.
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )
	
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NSVar' undefined."

		rem Env scale dynamically bounded: pre-allocation check, terminate immediately on exceed rather than silent bloat.
	if !_G.NSP! geq !_G.NSMAX! (
		>&2 echo [%~n0] Fatal: NS count !_G.NSP! at cap !_G.NSMAX! - env growth guard.
		2>con >&2 pause
		exit 1
	)

	set /a "_G.NSP += 1"
	set "_T.NW.NSBody=_G.NS[!_G.NSP!]"
	set "!_T.NW.NSBody!.Type=NSBody"
	set /a "_G.NSP += 1"
	set "_T.NW.NSMeta=_G.NS[!_G.NSP!]"
	set "!_T.NW.NSMeta!.Type=NSMeta"

	set "!_T.NW.NSBody!.RefCnt=1"
	set "!_T.NW.NSMeta!.Target=!_T.NW.NSBody!"
	
	set "_G.LEVEL[!_G.LEVEL!][!_T.NW.NSMeta!]=!_T.NW.NSMeta!"
	
	set "%~1=!_T.NW.NSMeta!"
%-|%

:NSUTIL_IsNSMeta *NS -> Bool
		rem Explicit naming `_T.CL.` (deprecated .for-var domain).
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

	set "_T.CL.T=%~1"
	call set "_T.CL.V=%%!_T.CL.T!%%"
	if not defined _T.CL.V set "_T.CL.V=!_T.CL.T!"
	call set "_T.CL.Type=%%!_T.CL.V!.Type%%"
	if /i "!_T.CL.Type!" == "NSMeta" (
		set "_T.CL.Res=1"
	) else (
		set "_T.CL.Res=0"
	)
	%<-% "_T.CL.Res"
%-|%

:NSUTIL_IsNSBody *NS -> Bool
		rem Explicit naming `_T.GET.` (deprecated .for-var domain).
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

	set "_T.GET.T=%~1"
	call set "_T.GET.V=%%!_T.GET.T!%%"
	if not defined _T.GET.V set "_T.GET.V=!_T.GET.T!"
	call set "_T.GET.Type=%%!_T.GET.V!.Type%%"
	if /i "!_T.GET.Type!" == "NSBody" (
		set "_T.GET.Res=1"
	) else (
		set "_T.GET.Res=0"
	)
	%<-% "_T.GET.Res"
%-|%

:NSUTIL_IsValidNS *NS -> Bool
		rem Explicit naming `_T.SET.` (deprecated .for-var domain).
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

	set "_T.SET.T=%~1"
	call set "_T.SET.V=%%!_T.SET.T!%%"
	if not defined _T.SET.V set "_T.SET.V=!_T.SET.T!"
	call set "_T.SET.Type=%%!_T.SET.V!.Type%%"
	if /i "!_T.SET.Type!" neq "NSMeta" (
		set "_T.SET.Res=0"
		%<-% "_T.SET.Res"
		%-|%
	)
	call set "_T.SET.Target=%%!_T.SET.V!.Target%%"
	if defined _T.SET.Target (
		call set "_T.SET.T2Type=%%!_T.SET.Target!.Type%%"
		if /i "!_T.SET.T2Type!" == "NSBody" (
			set "_T.SET.Res=1"
		) else (
			set "_T.SET.Res=0"
		)
	) else (
		set "_T.SET.Res=0"
	)
	%<-% "_T.SET.Res"
%-|%

:NSUTIL_AssertValidNS *NS
		rem Explicit naming `_T.V.` (deprecated .for-var domain).

	set "_T.V.T=%~1"
	%_G.DOTHIS% %-|%
	if not defined _G.NSUTIL (
		>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		2>con >&2 pause
		exit 1
	)

	if "%~1" == "" %?|% "'NS' undefined."
	%{% NSUTIL IsValidNS "!_T.V.T!" %}% %->% _T.V.Res
	if not "!_T.V.Res!" == "1" %?|% "not a valid NS."
%-|%

:NSUTIL_AssertValidNSBody *NS
		rem Explicit naming `_T.IM.` (deprecated .for-var domain).

	set "_T.IM.T=%~1"
	%_G.DOTHIS% %-|%
	if not defined _G.NSUTIL (
		>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		2>con >&2 pause
		exit 1
	)

	if "%~1" == "" %?|% "'NS' undefined."
	%{% NSUTIL IsNSBody "!_T.IM.T!" %}% %->% _T.IM.Res
	if not "!_T.IM.Res!" == "1" %?|% "not a valid NS."
%-|%

:NSUTIL_Clone *From *To
		rem Explicit naming `_T.IB.` (deprecated .for-var domain).

	set "_T.IB.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'From' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'To' undefined."

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

	set /a "_G.NSP += 1"
	set "_G.NS[!_G.NSP!].Type=NSMeta"
	if defined %~1.Target (
		set "_G.NS[!_G.NSP!].Target=!%~1.Target!"
		set "_T.IB.NSBody=!%~1.Target!"
	) else (
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "_T.IB.NSBody"
	)
	set /a "!_T.IB.NSBody!.RefCnt += 1"

	set "%~2=_G.NS[!_G.NSP!]"

	set "_G.LEVEL[!_G.LEVEL!][!%~2!]=!%~2!"
%-|%

:NSUTIL_CloneMeta *From *To
		rem Explicit naming `_T.CM.` (deprecated .for-var domain).

	set "_T.CM.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'From' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'To' undefined."

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

	set /a "_G.NSP += 1"
	set "_G.NS[!_G.NSP!].Type=NSMeta"
	if defined %~1.Target (
		set "_G.NS[!_G.NSP!].Target=!%~1.Target!"
		set "_T.CM.NSBody=!%~1.Target!"
	) else (
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "_T.CM.NSBody"
	)
	set /a "!_T.CM.NSBody!.RefCnt += 1"

	set "%~2=_G.NS[!_G.NSP!]"
%-|%

:NSUTIL_HasField *NS -> Bool
		rem Explicit naming `_T.HF.` (deprecated .for-var domain).

	set "_T.HF.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

	if defined %~1.Target (
		set "_T.HF.NSBody=!%~1.Target!"
	) else (
		%&% "!%~1!.Target" "_T.HF.NSBody"
	)
	if defined !_T.HF.NSBody!.Data.Key[%~2] (
		set "_T.HF.Res=1"
	) else (
		set "_T.HF.Res=0"
	)
	%<-% "_T.HF.Res"
%-|%

:NSUTIL_Get *NS Field *Val
		rem Explicit naming `_T.AV.` (deprecated .for-var domain).

	set "_T.AV.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
	%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

	if defined %~1.Target (
		set "_T.AV.NSBody=!%~1.Target!"
	) else (
		call set "_T.AV.NSBody=%%!%~1!.Target%%"
	)
	set "_T.AV.ValName=!_T.AV.NSBody!.Data.Value[%~2]"
	if defined _T.AV.ValName (
		call :NSUTIL_IndirectGet "_T.AV.ValName" "%~3"
	)
%-|%

:NSUTIL_IndirectGet *VarName *Out
	call set "%~2=%%!%~1!%%"
	exit /b 0
%-|%

:NSUTIL_Free *NS
		rem Explicit naming `_T.FR.` (deprecated .for-var domain).

	set "_T.FR.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

			%&% _G.RET _T.FR.RetBackup

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

	if defined %~1.Target (
		set "_T.FR.NSBody=!%~1.Target!"
		set "%~1.Type="
		set "%~1.Target="
	) else (
		%&% "!%~1!.Target" "_T.FR.NSBody"
		set "!%~1!.Type="
		set "!%~1!.Target="
	)

	call :NSUTIL_FreeNSBody "_T.FR.NSBody"

	%&% _T.FR.RetBackup _G.RET
%-|%

:NSUTIL_FreeNSBody *NS
		rem Explicit naming `_T.FB.` (deprecated .for-var domain, inline for /f %%a preserved).

	set "_T.FB.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	
	%_G.SKIPTHIS% %{% NSUTIL AssertValidNSBody "%~1" %}%

	%&% "!%~1!.RefCnt" "_T.FB.RefCnt"

	if !_T.FB.RefCnt! gtr 1 (
		set /a "!%~1!.RefCnt -= 1"
	) else (
		if !_T.FB.RefCnt! lss 1 (
			%?|% "double free detected."
		)

		set "!%~1!.Type="
		set "!%~1!.RefCnt="

		( set "!%~1!.Data.Key" ) > "%TEMP%\mal_f_!_G.LEVEL!.txt" 2>nul
		for /f "usebackq delims==" %%a in ("%TEMP%\mal_f_!_G.LEVEL!.txt") do (
			set "!%~1!.Data.Value[!%%a!]="
			set "%%a="
		)
	)
%-|%

:NSUTIL_CloneBody *NS *NewNS
		rem Explicit naming `_T.CB.` (deprecated .for-var domain, inline for /f %%a preserved).
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'NewNS' undefined."

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNSBody "%~1" %}%

	set /a "_G.NSP += 1"
	set "_T.CB.NewBody=_G.NS[!_G.NSP!]"
	set "!_T.CB.NewBody!.Type=NSBody"
	set "!_T.CB.NewBody!.RefCnt=1"

	( set "!%~1!.Data.Key" ) > "%TEMP%\mal_f_!_G.LEVEL!.txt" 2>nul
	for /f "usebackq delims==" %%a in ("%TEMP%\mal_f_!_G.LEVEL!.txt") do (
		set "!_T.CB.NewBody!.Data.Key[!%%a!]=!%%a!"

		call :NSUTIL_IsNSMeta "!%~1!.Data.Value[!%%a!]" %->% _T.CB.IsMeta
		if "!_T.CB.IsMeta!" == "1" (
			call :NSUTIL_CloneMeta "!%~1!.Data.Value[!%%a!]" "!_T.CB.NewBody!.Data.Value[!%%a!]"%
		) else (
			%&% "!%~1!.Data.Value[!%%a!]" "!_T.CB.NewBody!.Data.Value[!%%a!]"
		)
	)

	%&% "_T.CB.NewBody" "%~2"
%-|%

:NSUTIL_Set *NS Field *Val
		rem Explicit naming `_T.AB.` (deprecated .for-var domain).

	set "_T.AB.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
	%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

	%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

	if defined %~1.Target (
		set "_T.AB.NSBody=!%~1.Target!"
	) else (
		call set "_T.AB.NSBody=%%!%~1!.Target%%"
	)

	call set "_T.AB.RefCnt=%%!_T.AB.NSBody!.RefCnt%%"
	if !_T.AB.RefCnt! gtr 1 (
		set /a "!_T.AB.NSBody!.RefCnt -= 1"
		call :NSUTIL_CloneBody "_T.AB.NSBody" "_T.AB.NewBody"
		call set "_T.AB.NSBody=%%!_T.AB.NewBody!%%"
		if defined %~1.Target (
			set "!%~1!.Target=!_T.AB.NewBody!"
		) else (
			call set "!%~1!.Target=%%!_T.AB.NewBody!%%"
		)
	)

	set "_T.AB.V=%~3"

	call :NSUTIL_HasField "%~1" "%~2" %->% "_T.AB.HasField"
	if "!_T.AB.HasField!" == "1" (
		call set "_T.AB.OldVal=%%!_T.AB.NSBody!.Data.Value[%~2]%%"
		if "!_T.AB.OldVal!" == "!_T.AB.V!" (
			%-|%
		)
		%{% NSUTIL IsValidNS "!_T.AB.OldVal!" %}% %->% "_T.AB.IsMeta"
		if "!_T.AB.IsMeta!" == "1" (
			call :NSUTIL_Free "_T.AB.OldVal"
		)
	)

	set "!_T.AB.NSBody!.Data.Key[%~2]=%~2"
	call :NSUTIL_IsValidNS "!_T.AB.V!" %->% "_T.AB.IsNS"
	if "!_T.AB.IsNS!" == "1" (
		call :NSUTIL_CloneMeta "!_T.AB.V!" "!_T.AB.NSBody!.Data.Value[%~2]"
	) else (
		set "!_T.AB.NSBody!.Data.Value[%~2]=!_T.AB.V!"
	)
%-|%


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

:READER_ReadString _Str -> AST
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=%~1"

		%{n% %%.Reader %}
		%{s% %%.Reader Type Reader %}
		set "%%.TokenCount=0"
		set "%%.TokenPtr=1"
		%{s% %%.Reader TokenCount 0 %}
		%{s% %%.Reader TokenPtr 1 %}

		%{% READER Tokenize "!%%.Str!" "!%%.Reader!" %}%
		%?% (
			%-|%
		)

		%{g% %%.Reader TokenCount %%.TotalTokenNum %}
		if "!%%.TotalTokenNum!" == "0" (
			%??% "" Empty
			%-|%
		)

		%{% READER ReadForm %%.Reader %}% %->% %%.AST 
		%?% (
			%-|%
		)

		%<-% %%.AST
	)
%-|%

:READER_ReadForm *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unexpected EOF, need more token."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}

		if "!%%.CurToken!" == "(" (
			%{% READER ReadList "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == "[" (
			%{% READER ReadList "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == "{" (
			%{% READER ReadMap "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == "'" (
			%{% TYPES NewMal MalSym quote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "`" (
			%{% TYPES NewMal MalSym quasiquote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "@" (
			%{% TYPES NewMal MalSym deref %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "~" (
			%{% TYPES NewMal MalSym unquote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "~@" (
			%{% TYPES NewMal MalSym splice-unquote %}% %->% %%.SymQuote 
			%{g% "%~1" TokenPtr %%.TP %}
			set /a %%.TP += 1
			%{s% "%~1" TokenPtr !%%.TP! %}

			%{% READER ReadForm "%~1" %}% %->% %%.Mal 
			%?% (
				%-|%
			)
			%{% TYPES NewMalList %%.SymQuote %%.Mal %}% %->% %%.AST 
		) else if "!%%.CurToken!" == "$C" (
			%{% READER ReadMeta "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		) else if "!%%.CurToken!" == ")" (
			%??% "unexpected token ')'."
			%-|%
		) else if "!%%.CurToken!" == "]" (
			%??% "unexpected token ']'."
			%-|%
		) else if "!%%.CurToken!" == "}" (
			%??% "unexpected token '}'."
			%-|%
		) else if "!%%.CurToken:~,1!" == ";" (
			%??% "" Empty
		) else (
			%{% READER ReadAtom "%~1" %}% %->% %%.AST 
			%?% (
				%-|%
			)
		)

		%<-% %%.AST
	)
%-|%

:READER_ReadAtom *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unexpected EOF, need more token."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}
		set /a %%.TokenPtr += 1
		%{s% "%~1" TokenPtr !%%.TokenPtr! %}

		set /a %%.TestNum = %%.CurToken
		if "!%%.TestNum!" == "!%%.CurToken!" (
			%{% TYPES NewMal MalNum "!%%.CurToken!" %}% %->% %%.Mal 
		) else if "!%%.CurToken!" == "nil" (
			%{% TYPES NewMal MalNil nil %}% %->% %%.Mal 
		) else if "!%%.CurToken!" == "true" (
			%{% TYPES NewMal MalBool true %}% %->% %%.Mal 
		) else if "!%%.CurToken!" == "false" (
			%{% TYPES NewMal MalBool false %}% %->% %%.Mal 
		) else if "!%%.CurToken:~,2!" == "$D" (
			%{% TYPES NewMal MalStr "!%%.CurToken!" %}% %->% %%.Mal 
		) else if "!%%.CurToken:~,2!" == "$A" (
			%{% TYPES NewMal MalKwd "!%%.CurToken!" %}% %->% %%.Mal 
		) else (
			%{% TYPES NewMal MalSym "!%%.CurToken!" %}% %->% %%.Mal 
		)

		%<-% %%.Mal
	)
%-|%

:READER_ReadList *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}

		if "!%%.CurToken!" == "(" (
			%{% TYPES NewMalList %}% %->% %%.MalCode 
			%{s% %%.MalCode Type MalLst %}
		) else if "!%%.CurToken!" == "[" (
			%{% TYPES NewMalList %}% %->% %%.MalCode 
			%{s% %%.MalCode Type MalVec %}
		) else (
			%?|% "unexpected token '!%%.CurToken!'."
		)

		set /a %%.TokenPtr += 1
		%{s% "%~1" TokenPtr !%%.TokenPtr! %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		set "%%.Count=0"
	)
	:READER_ReadList_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		%{g% "%~1" Token[!%%.TokenPtr!] %%.CurToken %}

		if "!%%.CurToken!" == ")" (
			%{g% %%.MalCode Type %%.Type %}
			if "!%%.Type!" neq "MalLst" (
				%??% "unbalanced parenthesis."
				%-|%
			)
			set /a %%.TokenPtr += 1
			%{s% "%~1" TokenPtr !%%.TokenPtr! %}
			goto READER_ReadList_Pass
		)
		if "!%%.CurToken!" == "]" (
			%{g% %%.MalCode Type %%.Type %}
			if "!%%.Type!" neq "MalVec" (
				%??% "unbalanced parenthesis."
				%-|%
			)
			set /a %%.TokenPtr += 1
			%{s% "%~1" TokenPtr !%%.TokenPtr! %}
			goto READER_ReadList_Pass
		)
		set /a %%.Count += 1

		%{% READER ReadForm "%~1" %}% %->% %%.MalRet 
		%?% (
			%-|%
		)
		%{s% %%.MalCode Item[!%%.Count!] "!%%.MalRet!" %}

		goto READER_ReadList_Loop
	)
	:READER_ReadList_Pass
	for %%. in (_L[!_G.LEVEL!].) do (
		%{s% %%.MalCode Count !%%.Count! %}

		%<-% %%.MalCode
	)
%-|%

:READER_ReadMap *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TotalTokenNum %}

		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)

		set /a %%.TokenPtr += 1
		%{s% "%~1" TokenPtr !%%.TokenPtr! %}

		%{% TYPES NewMalMap %}% %->% %%.MalMap 
		%{g% %%.MalMap RawKeys %%.RawKeys %}
		
		set "%%.MapKeyCount=0"
		set "%%.RawKeyCount=0"
	)
	:READER_ReadMap_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "unbalanced parenthesis."
			%-|%
		)
		%{g% "%~1" Token[!%%.TokenPtr!] %%.Token %}
												if "!%%.Token!" == "}" (
			set /a %%.TokenPtr += 1
			%{s% "%~1" TokenPtr !%%.TokenPtr! %}
			goto READER_ReadMap_Pass
		)

		%{% READER ReadForm "%~1" %}% %->% %%.MalKey 
		%?% (
			%-|%
		)

		%{g% "!%%.MalKey!" Type %%.Type %}
		if "!%%.Type!" neq "MalStr" if "!%%.Type!" neq "MalKwd" (
			%??% "Map key must be 'MalStr' or 'MalKwd'."
			%-|%
		)

		%{g% "!%%.MalKey!" Value %%.RawKey %}
		
		%{g% "%~1" TokenPtr %%.TokenPtr %}
		if !%%.TokenPtr! gtr !%%.TotalTokenNum! (
			%??% "Unmatched map key-value pair."
			%-|%
		)

		%{% READER ReadForm "%~1" %}% %->% %%.MalVal 
		%?% (
			%-|%
		)

		%{g% %%.MalMap Item[!%%.RawKey!].Count %%.ExistCnt %}
		if "!%%.ExistCnt!" == "" (
			set /a %%.MapKeyCount += 1
			%{s% %%.MalMap Item[!%%.RawKey!].Count 1 %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[1].Key !%%.MalKey! %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[1].Value !%%.MalVal! %}

			set /a %%.RawKeyCount += 1
			%{s% "!%%.RawKeys!" Key[!%%.RawKeyCount!] "!%%.RawKey!" %}
		) else (
			set /a %%.ExistCnt += 1
			%{s% %%.MalMap Item[!%%.RawKey!].Count !%%.ExistCnt! %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[!%%.ExistCnt!].Key !%%.MalKey! %}
			%{s% %%.MalMap Item[!%%.RawKey!].Item[!%%.ExistCnt!].Value !%%.MalVal! %}
		)

		goto READER_ReadMap_Loop
	)
	:READER_ReadMap_Pass
	for %%. in (_L[!_G.LEVEL!].) do (
				%{s% %%.MalMap Count !%%.MapKeyCount! %}
		%{s% %%.MalMap RawKeyCount !%%.RawKeyCount! %}
		%{s% %%.MalMap RawKeys !%%.RawKeys! %}
		%<-% %%.MalMap
	)
%-|%

:READER_ReadMeta *Reader -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" TokenPtr %%.TP %}
		set /a %%.TP += 1
		%{s% "%~1" TokenPtr !%%.TP! %}

		%{g% "%~1" TokenPtr %%.TokenPtr %}
		%{g% "%~1" TokenCount %%.TokenCount %}
		if !%%.TokenPtr! gtr !%%.TokenCount! (
			%??% "Unexpected EOF, need more token."
			%-|%
		)

		%{% TYPES NewMal MalSym with-meta %}% %->% %%.MalSym 
		%{% READER ReadForm "%~1" %}% %->% %%.MalMeta 
		%?% (
			%-|%
		)
		%{% TYPES CheckType "!%%.MalMeta!" MalMap %}% %->% %%.IsCorrect 
		if "!%%.IsCorrect!" == "0" (
			%??% "Meta must be a map."
			%-|%
		)
		%{% READER ReadForm "%~1" %}% %->% %%.MalType 
		%?% (
			%-|%
		)

		%{% TYPES NewMalList %%.MalSym %%.MalType %%.MalMeta %}% %->% %%.MalRes 
		%<-% %%.MalRes
	)
%-|%

:READER_Tokenize _Str *Reader
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Line=%~1"
		set "%%.Reader=%~2"

		%{g% "!%%.Reader!" TokenCount %%.CurTokenNum %}
		set "%%.ParsingStr=False"
		set "%%.NormalToken="
	)
	:READER_Tokenizing_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "!%%.Line!" == "" (
			if "!%%.ParsingStr!" == "True" (
				%??% "unexpected EOF, string is incomplete."
				%-|%
			)
			goto READER_Tokenizing_Pass
		)
		if "!%%.ParsingStr!" == "False" (
			if "!%%.Line:~,1!" == " " (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "	" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "," (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "~@" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "~@" %}
				set "%%.Line=!%%.Line:~2!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "(" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "(" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == ")" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] ")" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "[" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "[" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "]" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "]" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "{" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "{" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "}" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "}" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "'" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "'" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "`" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "`" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "~" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "~" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == "@" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "@" %}
				set "%%.Line=!%%.Line:~1!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "$C" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "$C" %}
				set "%%.Line=!%%.Line:~2!"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "$D" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set "%%.Line=!%%.Line:~2!"
				set "%%.ParsingStr=True"
				set "%%.StrToken="
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,1!" == ";" (
				if defined %%.NormalToken (
					set /a %%.CurTokenNum += 1
					%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
					set "%%.NormalToken="
				)
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] ";!%%.Line!" %}
				set "%%.Line="
				goto READER_Tokenizing_Loop
			)

			set "%%.NormalToken=!%%.NormalToken!!%%.Line:~,1!"
			set "%%.Line=!%%.Line:~1!"
			goto READER_Tokenizing_Loop
		) else (
			if "!%%.Line:~,4!" == "\\\\$D" (
				set "%%.Line=!%%.Line:~4!"
				set "%%.StrToken=!%%.StrToken!\\$D"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "\\" (
				set "%%.Line=!%%.Line:~2!"
				set "%%.StrToken=!%%.StrToken!\\"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,3!" == "\$D" (
				set "%%.Line=!%%.Line:~3!"
				set "%%.StrToken=!%%.StrToken!\$D"
				goto READER_Tokenizing_Loop
			)
			if "!%%.Line:~,2!" == "$D" (
				set "%%.Line=!%%.Line:~2!"
				set "%%.ParsingStr=False"
				set /a %%.CurTokenNum += 1
				%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "$D!%%.StrToken!$D" %}
				goto READER_Tokenizing_Loop
			)
			set "%%.StrToken=!%%.StrToken!!%%.Line:~,1!"
			set "%%.Line=!%%.Line:~1!"
			goto READER_Tokenizing_Loop
		)
	)
	:READER_Tokenizing_Pass
	for %%. in (_L[!_G.LEVEL!].) do (
		if defined %%.NormalToken (
			set /a %%.CurTokenNum += 1
			%{s% "!%%.Reader!" Token[!%%.CurTokenNum!] "!%%.NormalToken!" %}
			set "%%.NormalToken="
		)
		%{s% "!%%.Reader!" TokenCount !%%.CurTokenNum! %}
		%<-% _
	)
%-|%

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

:PRINTER_PrintMalType &Mal -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" Type %%.Type %}%
		if "!%%.Type!" == "MalNum" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalSym" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalNil" (
			%{% STR FromVal "nil" %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalBool" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalKwd" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalStr" (
			%{g% "%~1" Value %%.Val %}
			%{% STR FromVar %%.Val %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalLst" (
			%{% STR New %}% %->% %%.StrMal
			%{% STR AppendVal %%.StrMal "(" %}
			%{g% "%~1" Count %%.Count %}
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.ItemMal %}
				%{% PRINTER PrintMalType "!%%.ItemMal!" %}% %->% %%.RetStrMal
				%{% STR AppendStr %%.StrMal %%.RetStrMal %}
				if "%%i" neq "!%%.Count!" (
					%{% STR AppendVal %%.StrMal " " %}
				)
			)
			%{% STR AppendVal %%.StrMal ")" %}
		) else if "!%%.Type!" == "MalVec" (
			%{% STR New %}% %->% %%.StrMal
			%{% STR AppendVal %%.StrMal "[" %}
			%{g% "%~1" Count %%.Count %}
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.ItemMal %}
				%{% PRINTER PrintMalType "!%%.ItemMal!" %}% %->% %%.RetStrMal
				%{% STR AppendStr %%.StrMal %%.RetStrMal %}
				if "%%i" neq "!%%.Count!" (
					%{% STR AppendVal %%.StrMal " " %}
				)
			)
			%{% STR AppendVal %%.StrMal "]" %}
		) else if "!%%.Type!" == "MalMap" (
			%{% PRINTER PrintMalMap "%~1" %}% %->% %%.StrMal
		) else if "!%%.Type!" == "MalFn" (
			%{% STR FromVal "#<function>" %}% %->% %%.StrMal
		) else (
			%?|% "MalType '!%%.Type!' not support yet."
		)
		%<-% %%.StrMal
	)
%-|%

:PRINTER_PrintMalMap &MalMap -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% STR New %}% %->% %%.Str
		%{% STR AppendVal %%.Str "{" %}
		%{g% "%~1" RawKeyCount %%.KeyCount %}
		%{g% "%~1" RawKeys %%.Keys %}
																								for /l %%i in (1 1 !%%.KeyCount!) do (
						%{g% "!%%.Keys!" Key[%%i] %%.RawKey %}
			%{g% "%~1" Item[!%%.RawKey!].Count %%.SameKeyCount %}
			for /l %%j in (1 1 !%%.SameKeyCount!) do (
				%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Key %%.KeyMal %}
				%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Value %%.ValMal %}
				%{% PRINTER PrintMalType "!%%.KeyMal!" %}% %->% %%.StrKey
				%{% PRINTER PrintMalType "!%%.ValMal!" %}% %->% %%.StrVal
				%{% STR AppendStr %%.Str %%.StrKey %}
				%{% STR AppendVal %%.Str " " %}
				%{% STR AppendStr %%.Str %%.StrVal %}
				if "%%j" neq "!%%.SameKeyCount!" (
					%{% STR AppendVal %%.Str " " %}
				)
			)
			if "%%i" neq "!%%.KeyCount!" (
				%{% STR AppendVal %%.Str " " %}
			)
		)
		%{% STR AppendVal %%.Str "}" %}
		%<-% %%.Str
	)
%-|%

:PRINTER_PrStrMal &Mal -> Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% PRINTER PrintMalType "%~1" %}% %->% %%.StrMal
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		%<-% %%.Result
	)
%-|%

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

:STR_New -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Str %}
		%{s% %%.Str Type String %}
		set "%%.LineCount=0"
		%{s% %%.Str LineCount 0 %}
		%<-% %%.Str
	)
%-|%

:STR_FromVar _Var -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Str %}
		%{s% %%.Str Type String %}
		%{s% %%.Str LineCount 1 %}
		%{s% %%.Str Line[1] "!%~1!" %}
		%<-% %%.Str
	)
%-|%

:STR_FromVal _Val -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Str %}
		%{s% %%.Str Type String %}
		%{s% %%.Str LineCount 1 %}
		%{s% %%.Str Line[1] "%~1" %}
		%<-% %%.Str
	)
%-|%

:STR_AppendStr &Str &NewStr
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		%{g% "%~2" LineCount %%.LineCount2 %}
		if !%%.LineCount! geq 1 (
			if !%%.LineCount2! geq 1 (
				%{g% "%~1" Line[!%%.LineCount!] %%.Line %}
				%{g% "%~2" Line[1] %%.Line2 %}
				set "%%.NewLine=!%%.Line!!%%.Line2!"
				%{s% "%~1" Line[!%%.LineCount!] "!%%.NewLine!" %}
			)
		)
		for /l %%i in (2 1 !%%.LineCount2!) do (
			set /a %%.LineCount += 1
			%{g% "%~2" Line[%%i] %%.Line3 %}
			%{s% "%~1" Line[!%%.LineCount!] "!%%.Line3!" %}
		)
		%{s% "%~1" LineCount !%%.LineCount! %}
		%<-% _
	)
%-|%

:STR_AppendVal &Str _Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		if "!%%.LineCount!" == "0" (
			set "%%.LineCount=1"
			%{s% "%~1" LineCount 1 %}
		)
		%{g% "%~1" Line[!%%.LineCount!] %%.LastLine %}
		if defined %%.LastLine (
			set "%%.NewLine=!%%.LastLine!%~2"
			%{s% "%~1" Line[!%%.LineCount!] "!%%.NewLine!" %}
		) else (
			%{s% "%~1" Line[!%%.LineCount!] "%~2" %}
		)
		%<-% _
	)
%-|%

:STR_AppendVar &Str _Var
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		if "!%%.LineCount!" == "0" (
			set "%%.LineCount=1"
			%{s% "%~1" LineCount 1 %}
		)
		%{g% "%~1" Line[!%%.LineCount!] %%.LastLine %}
		if defined %%.LastLine (
			set "%%.NewLine=!%%.LastLine!!%~2!"
			%{s% "%~1" Line[!%%.LineCount!] "!%%.NewLine!" %}
		) else (
			%{s% "%~1" Line[!%%.LineCount!] "!%~2!" %}
		)
		%<-% _
	)
%-|%

:STR_GetStr &Str -> Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		set "%%.Result="
		for /l %%i in (1 1 !%%.LineCount!) do (
			%{g% "%~1" Line[%%i] %%.Line %}
			set "%%.Result=!%%.Result!!%%.Line!"
		)
		%<-% %%.Result
	)
%-|%

:STR_GetVar &Str *Var
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		set "%%.Result="
		for /l %%i in (1 1 !%%.LineCount!) do (
			%{g% "%~1" Line[%%i] %%.Line %}
			set "%%.Result=!%%.Result!!%%.Line!"
		)
		%&% %%.Result "%~2"
	)
%-|%

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

:TYPES_NewMal _Type _Value -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Type=%~1"
		set "%%.Value=%~2"
		%{n% %%.Mal %}
		%{s% %%.Mal Type !%%.Type! %}
		%{s% %%.Mal Value "!%%.Value!" %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewMalList Mal1 Mal2 ... -> MalList
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Mal %}
		%{s% %%.Mal Type MalLst %}
		set "%%.Count=0"
	)
	:TYPES_NewMalList_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			%{s% %%.Mal Item[!%%.Count!] "%~1" %}
			shift
			goto TYPES_NewMalList_Loop
		)
		%{s% %%.Mal Count !%%.Count! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewMalVec Mal1 Mal2 ... -> MalVec
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Mal %}
		%{s% %%.Mal Type MalVec %}
		set "%%.Count=0"
	)
	:TYPES_NewMalVec_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "%~1" neq "" (
			set /a %%.Count += 1
			%{s% %%.Mal Item[!%%.Count!] "%~1" %}
			shift
			goto TYPES_NewMalVec_Loop
		)
		%{s% %%.Mal Count !%%.Count! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewMalMap -> MalMap
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Mal %}
		%{s% %%.Mal Type MalMap %}
		set "%%.Count=0"
		set "%%.RawKeyCount=0"
		%{n% %%.RawKeys %}
		%{s% %%.Mal RawKeys !%%.RawKeys! %}
		%{s% %%.Mal Count !%%.Count! %}
		%{s% %%.Mal RawKeyCount !%%.RawKeyCount! %}
		%<-% %%.Mal
	)
%-|%

:TYPES_NewBatFn _Mod _Name [_AutoEval=True] -> MalFn
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mod=%~1"
		set "%%.Name=%~2"
		if "%~3" == "False" (
			set "%%.AutoEval=False"
		) else (
			set "%%.AutoEval=True"
		)

		%{n% %%.MalFn %}
		%{s% %%.MalFn Type MalFn %}
		%{s% %%.MalFn SubType BAT %}
		%{s% %%.MalFn Mod !%%.Mod! %}
		%{s% %%.MalFn Name !%%.Name! %}
		%{s% %%.MalFn AutoEval !%%.AutoEval! %}
		%<-% %%.MalFn
	)
%-|%

:TYPES_NewMalFn _Binds _Body _Env -> MalFn
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.MalFn %}
		%{s% %%.MalFn Type MalFn %}
		%{s% %%.MalFn SubType MAL %}
		%{s% %%.MalFn AutoEval True %}
		%{s% %%.MalFn Binds %~1 %}
		%{s% %%.MalFn Body %~2 %}
		%{s% %%.MalFn Env %~3 %}
		%<-% %%.MalFn
	)
%-|%

:TYPES_CheckType &Mal _Type1 _Type2 ... -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Bool=0"
		%{g% "%~1" Type %%.Type %}
	)
	:TYPES_CheckType_Loop
	for %%. in (_L[!_G.LEVEL!].) do (
		if "%~1" neq "" (
			if "%~1" equ "!%%.Type!" (
				set "%%.Bool=1"
			)
			shift
			goto TYPES_CheckType_Loop
		)
		%<-% %%.Bool
	)
%-|%

:TYPES_CopyMal &Mal -> ClonedMal
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" Type %%.Type %}
		if "!%%.Type!" == "MalNum" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalNum "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalSym" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalSym "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalNil" (
			%{% TYPES NewMal MalNil nil %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalBool" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalBool "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalKwd" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalKwd "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalStr" (
			%{g% "%~1" Value %%.Val %}
			%{% TYPES NewMal MalStr "!%%.Val!" %}% %->% %%.Ret
		) else if "!%%.Type!" == "MalLst" (
			%{g% "%~1" Count %%.Count %}
			%{% TYPES NewMalList %}% %->% %%.Ret
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.Item %}
				%{% TYPES CopyMal "!%%.Item!" %}% %->% %%.NewItem
				%{s% %%.Ret Item[%%i] !%%.NewItem! %}
			)
			%{s% %%.Ret Count !%%.Count! %}
		) else if "!%%.Type!" == "MalVec" (
			%{g% "%~1" Count %%.Count %}
			%{% TYPES NewMalVec %}% %->% %%.Ret
			for /l %%i in (1 1 !%%.Count!) do (
				%{g% "%~1" Item[%%i] %%.Item %}
				%{% TYPES CopyMal "!%%.Item!" %}% %->% %%.NewItem
				%{s% %%.Ret Item[%%i] !%%.NewItem! %}
			)
			%{s% %%.Ret Count !%%.Count! %}
		) else if "!%%.Type!" == "MalMap" (
			%{% TYPES NewMalMap %}% %->% %%.Ret
			%{g% "%~1" RawKeyCount %%.RKCount %}
			%{g% "%~1" RawKeys %%.RawKeys %}
			set "%%.MapCnt=0"
			for /l %%i in (1 1 !%%.RKCount!) do (
				%{g% "!%%.RawKeys!" Key[%%i] %%.RawKey %}
				%{g% "%~1" Item[!%%.RawKey!].Count %%.SameCnt %}
				for /l %%j in (1 1 !%%.SameCnt!) do (
					%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Key %%.KeyMal %}
					%{g% "%~1" Item[!%%.RawKey!].Item[%%j].Value %%.ValMal %}
					%{% TYPES CopyMal "!%%.KeyMal!" %}% %->% %%.NewKey
					%{% TYPES CopyMal "!%%.ValMal!" %}% %->% %%.NewVal
					%{g% "!%%.NewKey!" Value %%.RawK %}
					if not "!%%.RawK!" == "" (
						%{g% "%~1" Item[!%%.RawK!].Count %%.ExistCnt %}
						if "!%%.ExistCnt!" == "" (
							set /a %%.MapCnt += 1
							%{s% %%.Ret Item[!%%.RawK!].Count 1 %}
							%{s% %%.Ret Item[!%%.RawK!].Item[1].Key !%%.NewKey! %}
							%{s% %%.Ret Item[!%%.RawK!].Item[1].Value !%%.NewVal! %}
							%{s% "!%%.RawKeys!" Key[!%%.MapCnt!] !%%.RawK! %}
						)
					)
				)
			)
			%{s% %%.Ret Count !%%.MapCnt! %}
			%{s% %%.Ret RawKeyCount !%%.MapCnt! %}
			%{s% %%.Ret RawKeys !%%.RawKeys! %}
		) else if "!%%.Type!" == "MalFn" (
			%{g% "%~1" SubType %%.SubType %}
			if "!%%.SubType!" == "BAT" (
				%{g% "%~1" Mod %%.Mod %}
				%{g% "%~1" Name %%.Name %}
				%{g% "%~1" AutoEval %%.AutoEval %}
				%{% TYPES NewBatFn "!%%.Mod!" "!%%.Name!" "!%%.AutoEval!" %}% %->% %%.Ret
			) else (
				%{g% "%~1" Binds %%.Binds %}
				%{g% "%~1" Body %%.Body %}
				%{g% "%~1" Env %%.Env %}
				%{% TYPES NewMalFn "!%%.Binds!" "!%%.Body!" "!%%.Env!" %}% %->% %%.Ret
			)
		) else (
			%?|% "Unknown type '!%%.Type!' for copy."
		)
		%<-% %%.Ret
	)
%-|%

:TYPES_SameObjects &Mal1 &Mal2 -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if "!%~1!" == "!%~2!" (
			%<-% 1
			%-|%
		)
		%<-% 0
	)
%-|%

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

:ENV_New _Outer -> Env
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Env %}
		%{s% %%.Env Type Environment %}
		if "%~1" neq "_" (
			%{s% %%.Env Outer "%~1" %}
		) else (
			%{s% %%.Env Outer _ %}
		)
		set "%%.ItemCnt=0"
		%{s% %%.Env ItemCount 0 %}
		%<-% %%.Env
	)
%-|%

:ENV_Set *Env _Key *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" ItemCount %%.Cnt %}
		set /a %%.Cnt += 1
		%{s% "%~1" Key[!%%.Cnt!] "%~2" %}
		%{s% "%~1" Val[!%%.Cnt!] "%~3" %}
		%{s% "%~1" ItemCount !%%.Cnt! %}
	)
%-|%

:ENV_Find *Env _Key -> Env?
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Env=%~1"
		set "%%.Ret=_"
		:ENV_Find_Loop
		if "!%%.Env!" == "_" (
			%<-% %%.Ret
			%-|%
		)
		%{g% "!%%.Env!" ItemCount %%.Cnt %}
		set "%%.Found=0"
		for /l %%i in (1 1 !%%.Cnt!) do (
			if "!%%.Found!" == "0" (
				%{g% "!%%.Env!" Key[%%i] %%.CurKey %}
				if "!%%.CurKey!" == "%~2" (
					set "%%.Found=1"
					set "%%.Ret=!%%.Env!"
				)
			)
		)
		if "!%%.Found!" == "0" (
			%{g% "!%%.Env!" Outer %%.Env %}
			goto ENV_Find_Loop
		)
		%<-% %%.Ret
	)
%-|%

:ENV_Get *Env _Key -> Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% ENV Find "%~1" "%~2" %}% %->% %%.FoundEnv 
		if "!%%.FoundEnv!" == "_" (
			%??% "Symbol '%~2' not found."
			%-|%
		)
		%{g% "!%%.FoundEnv!" ItemCount %%.Cnt %}
		set "%%.Ret=_"
		for /l %%i in (1 1 !%%.Cnt!) do (
			%{g% "!%%.FoundEnv!" Key[%%i] %%.CurKey %}
			if "!%%.CurKey!" == "%~2" (
				%{g% "!%%.FoundEnv!" Val[%%i] %%.Ret %}
			)
		)
		%<-% %%.Ret
	)
%-|%

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

:IO_ReadEncLine -> Line
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.PACKED (
			for /f "tokens=* eol=" %%a in (
				'call READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		) else (
			for /f "tokens=* eol=" %%a in (
				'call "%~s0" CALL_READLINE'
			) do (
				set "%%.Line=%%~a"
			)
		)

		if defined MAL_BATCH_IMPL_ECHO_STDIN (
			%{% IO WriteEncLine %%.Line %}%
		)

		%<-% %%.Line
	)
%-|%

:IO_WriteEncLine Line
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if "%~1" == "" %?|% "Arg 'Line' is empty."

		if not defined _G.PACKED (
			echo."!%~1!"| call WRITEALL
		) else (
			echo."!%~1!"| call "%~s0" CALL_WRITEALL
		)
	)
%-|%

:IO_WriteVal Val
	for %%. in (_L[!_G.LEVEL!].) do (
		<nul set /p "=%~1"
	)
%-|%

:IO_WriteVar Var
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if "%~1" == "" %?|% "Arg 'Var' is empty."
		<nul set /p "=!%~1!"
	)
%-|%

:IO_WriteStr
	for %%. in (_L[!_G.LEVEL!].) do (
		%?|% TODO
	)
%-|%

:IO_WriteErrLineVal Val
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.V=%~1"
		if defined MAL_BATCH_IMPL_NO_STDERR (
			echo.!%%.V!
		) else (
			2>&1 echo.!%%.V!
		)
	)
%-|%

:IO_WriteErrLineVar _Var
	for %%. in (_L[!_G.LEVEL!].) do (
		if defined MAL_BATCH_IMPL_NO_STDERR (
			echo.!%~1!
		) else (
			2>&1 echo.!%~1!
		)
	)
%-|%

:READLINE
setlocal disabledelayedexpansion
for /f "delims=#" %%. in (
	'prompt #$E# ^& echo on ^& for %%_ in ^( . ^) do rem'
) do (
	set "_Esc=%%."
)

set _In= & set /p "_In="
for /f "delims=" %%. in ("%_Esc%") do (
	if defined _In (
		call set "_In=%%_In:"=%%.D%%"
		call set "_In=%%_In:!=%%.E%%"
		setlocal ENABLEDELAYEDEXPANSION
		(
			set "_In=!_In:^=%%.C!"
			set "_In2="
			:READLINE_Replace
			if defined _In (
				if "!_In:~,1!" == "%%" (
					set "_In2=!_In2!%_Esc%P"
				) else (
					set "_In2=!_In2!!_In:~,1!"
				)
				set "_In=!_In:~1!"
				goto READLINE_Replace
			)
			:READLINE_Replace2
			if defined _In2 (
				if "!_In2:~,1!" == "%_Esc%" (
					set "_In3=!_In3!$"
				) else if "!_In2:~,1!" == "$" (
					set "_In3=!_In3!$$"
				) else if "!_In2:~,1!" == ":" (
					set "_In3=!_In3!$A"
				) else (
					set "_In3=!_In3!!_In2:~,1!"
				)
				set "_In2=!_In2:~1!"
				goto READLINE_Replace2
			)
			echo.!_In3!
		)
		endlocal
	)
)
exit /b 0

:WRITEALL
@echo off & setlocal ENABLEDELAYEDEXPANSION

for /f "delims=" %%i in ('more') do (
	set "_Out=%%~i"
	set _OutBuf=
	:WRITEALL_Loop
	if "!_Out:~,2!" == "$$" (
		set "_OutBuf=!_OutBuf!$"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$E" (
		set "_OutBuf=!_OutBuf!^!"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$C" (
		set "_OutBuf=!_OutBuf!^^"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$D" (
		set "_OutBuf=!_OutBuf!^""
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,1!" == "=" (
		set "_OutBuf=!_OutBuf!="
		set "_Out=!_Out:~1!"
		goto WRITEALL_Loop
	) else if "!_Out:~,1!" == " " (
		set "_OutBuf=!_OutBuf! "
		set "_Out=!_Out:~1!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$P" (
		set "_OutBuf=!_OutBuf!%%"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if "!_Out:~,2!" == "$A" (
		set "_OutBuf=!_OutBuf!:"
		set "_Out=!_Out:~2!"
		goto WRITEALL_Loop
	) else if defined _Out (
		set "_OutBuf=!_OutBuf!!_Out:~,1!"
		set "_Out=!_Out:~1!"
		goto WRITEALL_Loop
	)
	echo.!_OutBuf!
)
exit /b 0
