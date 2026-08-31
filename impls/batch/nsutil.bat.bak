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
			call "%~dp0UTIL.bat" :UTIL_Init "%~1"
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
			set "{d=call :NSUTIL_SetDirect"
		) else (
			set "{n=call "%~dp0NSUTIL.bat" :NSUTIL_New"
			set "{c=call "%~dp0NSUTIL.bat" :NSUTIL_Clone"
			set "{g=call "%~dp0NSUTIL.bat" :NSUTIL_Get"
			set "{s=call "%~dp0NSUTIL.bat" :NSUTIL_Set"
			set "{d=call "%~dp0NSUTIL.bat" :NSUTIL_SetDirect"
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

	if defined _G.NXFREE (
			rem Reuse free slot: pop [meta,body] pair, don't move _G.NSP (1: reuse doesn't grow high-water mark).
		set "_T.NW.MI=_G.NXFREE"
		set "_G.NXFREE=!_G.NSFREENEXT[!_T.NW.MI!]!"
		set "_G.NSFREENEXT[!_T.NW.MI!]="
		set "_T.NW.BI=_G.NXFREE"
		set "_G.NXFREE=!_G.NSFREENEXT[!_T.NW.BI!]!"
		set "_G.NSFREENEXT[!_T.NW.BI!]="
		set "_T.NW.NSMeta=_G.NS[!_T.NW.MI!]"
		set "_T.NW.NSBody=_G.NS[!_T.NW.BI!]"
	) else (
		if !_G.NSP! geq !_G.NSMAX! (
			>&2 echo [%~n0] Fatal: NS count !_G.NSP! at cap !_G.NSMAX! - env growth guard.
			2>con >&2 pause
			exit 1
		)
		set /a "_G.NSP += 1"
		set "_T.NW.NSBody=_G.NS[!_G.NSP!]"
		set /a "_G.NSP += 1"
		set "_T.NW.NSMeta=_G.NS[!_G.NSP!]"
	)
	set "!_T.NW.NSBody!.Type=NSBody"
	set "!_T.NW.NSMeta!.Type=NSMeta"

	set "!_T.NW.NSBody!.RefCnt=1"
	set "!_T.NW.NSMeta!.Target=!_T.NW.NSBody!"
	set "!_T.NW.NSMeta!.RC=1"
	
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
	rem Round6B: prefix-guard first. Non "_G.NS[" values (e.g. "< > & |")
rem never reach the %% indirection below, which would build illegal %<% 
rem text and crash parse (seen on MLess set2 storing value "<").
if not "!_T.SET.T:~0,6!" == "_G.NS[" (
		set "_T.SET.Res=0"
		%<-% "_T.SET.Res"
		%-|%
	)
	set "_T.SET.Ty=!_T.SET.T!.Type"
	call set "_T.SET.Type=%%!_T.SET.Ty!%%"
	if /i "!_T.SET.Type!" neq "NSMeta" (
		set "_T.SET.Res=0"
		%<-% "_T.SET.Res"
		%-|%
	)
	set "_T.SET.Tg=!_T.SET.T!.Target"
	call set "_T.SET.Target=%%!_T.SET.Tg!%%"
	if defined _T.SET.Target (
		set "_T.SET.T2Type=!_T.SET.Target!.Type"
		call set "_T.SET.T2Type=%%!_T.SET.T2Type!%%"
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
	call :NSUTIL_IsValidNS "!_T.V.T!" %->% _T.V.Res
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
	call :NSUTIL_IsNSBody "!_T.IM.T!" %->% _T.IM.Res
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

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

	set /a "_G.NSP += 1"
	set "_G.NS[!_G.NSP!].Type=NSMeta"
	set "_G.NS[!_G.NSP!].RC=1"
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

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

	set /a "_G.NSP += 1"
	set "_G.NS[!_G.NSP!].Type=NSMeta"
	set "_G.NS[!_G.NSP!].RC=1"
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

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

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

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

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
	rem Round6B: RCMODE=on dispatch FreeRC (DecRef + drain)
	if defined _G.RCMODE (
		call :NSUTIL_FreeRC "%~1"
		%-|%
	)

	set "_T.FR.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

			%&% _G.RET _T.FR.RetBackup

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

	if defined %~1.Target (
		set "_T.FR.NSBody=!%~1.Target!"
		set "_T.FR.H=%~1"
		set "%~1.Type="
		set "%~1.Target="
	) else (
		%&% "!%~1!.Target" "_T.FR.NSBody"
		set "_T.FR.H=!%~1!"
		set "!%~1!.Type="
		set "!%~1!.Target="
	)

	call :NSUTIL_FreeNSBody "_T.FR.NSBody"

		rem Slot recycling: when _G.RECYCLE on, push own body pair onto free list (TCO loop scope).
	if defined _G.RECYCLE if "!_T.FR.H:~0,6!" == "_G.NS[" (
		set "_T.FR.MI=!_T.FR.H:~6,-1!"
		set "_T.FR.BI=!_T.FR.NSBody:~6,-1!"
		set /a "_T.FR.CK = _T.FR.MI - 1"
		if "!_T.FR.BI!" == "!_T.FR.CK!" (
			set "_G.NSFREENEXT[!_T.FR.BI!]=!_G.NXFREE!"
			set "_G.NXFREE=!_T.FR.BI!"
			set "_G.NSFREENEXT[!_T.FR.MI!]=!_G.NXFREE!"
			set "_G.NXFREE=!_T.FR.MI!"
		)
	)

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
	
	%_G.SKIPTHIS% call :NSUTIL_AssertValidNSBody "%~1"

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
	rem Round6B: RCMODE=on dispatch CloneBodyRC (shared handle refs, no wrapper)
	if defined _G.RCMODE (
		call :NSUTIL_CloneBodyRC "%~1" "%~2"
		%-|%
	)
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'NewNS' undefined."

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNSBody "%~1"

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
	rem Round6B: RCMODE=on dispatch SetRC (COW + overwrite DecRef + IncRef store)
	if defined _G.RCMODE (
		call :NSUTIL_SetRC "%~1" "%~2" "%~3"
		%-|%
	)

	set "_T.AB.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
	%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

	if defined %~1.Target (
		set "_T.AB.NSBody=!%~1.Target!"
	) else (
		call set "_T.AB.NSBody=%%!%~1!.Target%%"
	)

	set "_T.AB.V=%~3"

		rem Narrow COW trigger surface (#3): same-value short-circuit first -- deep copy only if changed,
		rem avoid wasteful CloneBody full-field deep copy. Free step re-reads current field value, preserving semantics.
	call :NSUTIL_HasField "%~1" "%~2" %->% "_T.AB.HasField"
	if "!_T.AB.HasField!" == "1" (
		call set "_T.AB.CurVal=%%!_T.AB.NSBody!.Data.Value[%~2]%%"
		if "!_T.AB.CurVal!" == "!_T.AB.V!" (
			%-|%
		)
	)

	call set "_T.AB.RefCnt=%%!_T.AB.NSBody!.RefCnt%%"
	if !_T.AB.RefCnt! gtr 1 (
		set /a "!_T.AB.NSBody!.RefCnt -= 1"
		call :NSUTIL_CloneBody "_T.AB.NSBody" "_T.AB.NewBody"
		set "_T.AB.NSBody=!_T.AB.NewBody!"
		if defined %~1.Target (
			set "%~1.Target=!_T.AB.NewBody!"
		) else (
			call set "%~1.Target=%%!_T.AB.NewBody!%%"
		)
	)

	if "!_T.AB.HasField!" == "1" (
		call set "_T.AB.CurVal=%%!_T.AB.NSBody!.Data.Value[%~2]%%"
		call :NSUTIL_IsValidNS "!_T.AB.CurVal!" %->% "_T.AB.IsMeta"
		if "!_T.AB.IsMeta!" == "1" (
			call :NSUTIL_Free "_T.AB.CurVal"
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

:NSUTIL_SetDirect *NS Field *Val
		rem Env direct-write (#step4 recursion fix): def! bypasses COW when modifying shared env,
		rem preserving MAL ref semantics -- all closures capturing that env see the new binding.
		rem Explicit naming `_T.SD.` (deprecated .for-var domain).
	rem Round6B: RCMODE=on dispatch SetDirectRC (no COW, write-through)
	if defined _G.RCMODE (
		call :NSUTIL_SetDirectRC "%~1" "%~2" "%~3"
		%-|%
	)

	set "_T.SD.T=%~1"
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )

	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
	%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
	%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

	%_G.SKIPTHIS% call :NSUTIL_AssertValidNS "%~1"

	if defined %~1.Target (
		set "_T.SD.NSBody=!%~1.Target!"
	) else (
		call set "_T.SD.NSBody=%%!%~1!.Target%%"
	)

	set "_T.SD.V=%~3"

	call :NSUTIL_HasField "%~1" "%~2" %->% "_T.SD.HasField"
	if "!_T.SD.HasField!" == "1" (
		call set "_T.SD.CurVal=%%!_T.SD.NSBody!.Data.Value[%~2]%%"
		call :NSUTIL_IsValidNS "!_T.SD.CurVal!" %->% "_T.SD.IsMeta"
		if "!_T.SD.IsMeta!" == "1" (
			call :NSUTIL_Free "_T.SD.CurVal"
		)
	)

	set "!_T.SD.NSBody!.Data.Key[%~2]=%~2"
	call :NSUTIL_IsValidNS "!_T.SD.V!" %->% "_T.SD.IsNS"
	if "!_T.SD.IsNS!" == "1" (
		call :NSUTIL_CloneMeta "!_T.SD.V!" "!_T.SD.NSBody!.Data.Value[%~2]"
	) else (
		set "!_T.SD.NSBody!.Data.Value[%~2]=!_T.SD.V!"
	)
%-|%
:UTIL_SetRet

	if defined _G.NSUTIL (

		call set "_T.SR.Type=%%!%~1!.Type%%"

		if /i "!_T.SR.Type!" == "NSMeta" (

			if defined _G.LEVEL[!_G.LEVEL!][!%~1!] (

				set "_G.LEVEL[!_G.LEVEL!][!%~1!]="

				set /a "_T.SR.PrevLevel = _G.LEVEL - 1"

				set "_G.RET=!%~1!"

				set "_G.LEVEL[!_T.SR.PrevLevel!][!_G.RET!]=!_G.RET!"

			) else (

				set "_G.RET=!%~1!"

			)

		) else (

			set "_G.RET=!%~1!"

		)

	) else (

		set "_G.RET=!%~1!"

	)

exit /b 0



:UTIL_GetRet

	if not defined _G.ERR (

		set "%~1=!_G.RET!"

	)

	set "_G.RET="

exit /b 0

rem ============================================================
	rem Round6B RC refcount refactor (RCMODE=on branch, round6.md six touchpoints)
	rem store +1 IncRef / overwrite -1 DecRef / Free both forms / FreeNSBody per-field /
	rem work queue _G.DESTROY + Drain / decref underflow assertion.
	rem input 3 forms normalized: raw handle _G.NS[n] / var name / registry _G.LEVEL[L][ns].
rem ============================================================

:NSUTIL_IncRef *NS
	rem NS ref +1. dead-ref / non-NS: silent skip.
	set "_T.IR.Q=%~1"
	if not "!_T.IR.Q:~0,6!" == "_G.NS[" (
		call set "_T.IR.Q=%%!%~1!%%"
		if not defined _T.IR.Q %-|%
		if "!_T.IR.Q:~0,6!" == "_G.LEVEL[" call set "_T.IR.Q=%%!_T.IR.Q!%%"
	)
	if not "!_T.IR.Q:~0,6!" == "_G.NS[" %-|%
	call set "_T.IR.RC=%%!_T.IR.Q!.RC%%"
	if not defined _T.IR.RC set "_T.IR.RC=0"
	set /a "_T.IR.RC += 1"
	set "!_T.IR.Q!.RC=!_T.IR.RC!"
	set "_T.IR.Q="
	set "_T.IR.RC="
%-|%

:NSUTIL_DecRef *NS
	rem NS ref -1; zero pushes into _G.DESTROY queue. underflow aborts.
	rem dead-ref / already released: skip silently (idempotent, no double-free).
	set "_T.DC.Q=%~1"
	if not "!_T.DC.Q:~0,6!" == "_G.NS[" (
		call set "_T.DC.Q=%%!%~1!%%"
		if not defined _T.DC.Q %-|%
		if "!_T.DC.Q:~0,6!" == "_G.LEVEL[" call set "_T.DC.Q=%%!_T.DC.Q!%%"
	)
	if not "!_T.DC.Q:~0,6!" == "_G.NS[" %-|%
	call set "_T.DC.RC=%%!_T.DC.Q!.RC%%"
	if not defined _T.DC.RC set "_T.DC.RC=0"
	if !_T.DC.RC! lss 1 %?|% "decref underflow on [%~1]."
	set /a "_T.DC.RC -= 1"
	set "!_T.DC.Q!.RC=!_T.DC.RC!"
	if "!_T.DC.RC!" == "0" (
		set /a "_G.DESTROY.C += 1"
		set "_G.DESTROY[!_G.DESTROY.C!]=!_T.DC.Q!"
	)
	set "_T.DC.Q="
	set "_T.DC.RC="
%-|%

:NSUTIL_DrainDestroy
	rem drain _G.DESTROY queue; each: meta->body unlink (body RefCnt-1);
	rem body dead: per-field DecRef + clear; clear meta slot; RECYCLE adjacent pair -> NXFREE.
	set "_T.DR.H="
	set "_T.DR.B="
	set "_T.DR.REF="
	set "_T.DR.FV="
	set "_T.DR.FS="
	set "_T.DR.FM="
	set "_T.DR.BR="
:NSUTIL_DrainDestroy_Chk
	if defined _G.DESTROY.C (
		set "_T.DR.H=!_G.DESTROY[!_G.DESTROY.C!]!"
		set "_G.DESTROY[!_G.DESTROY.C!]="
		set /a "_G.DESTROY.C -= 1"
		if "!_G.DESTROY.C!" == "0" set "_G.DESTROY.C="
		if defined _T.DR.H (
			call set "_T.DR.B=%%!_T.DR.H!.Target%%"
			if "!_T.DR.B:~0,6!" == "_G.NS[" (
				call set "_T.DR.BR=%%!_T.DR.B!.RefCnt%%"
				if not defined _T.DR.BR set "_T.DR.BR=0"
				set /a "_T.DR.BR -= 1"
				set "!_T.DR.B!.RefCnt=!_T.DR.BR!"
				if "!_T.DR.BR!" == "0" (
					rem body dead: per-field DecRef + clear
					( set "!_T.DR.B!.Data.Key" ) > "%TEMP%\mal_rb_!_G.LEVEL!.txt" 2>nul
					for /f "usebackq delims==" %%k in ("%TEMP%\mal_rb_!_G.LEVEL!.txt") do (
						call set "_T.DR.FV=%%!_T.DR.B!.Data.Value[!%%k!]%%"
						set "_T.DR.FS=!_T.DR.FV:~0,6!"
						if "!_T.DR.FS!" == "_G.NS[" (
							call :NSUTIL_IsValidNS "!_T.DR.FV!" %->% _T.DR.FM
							if "!_T.DR.FM!" == "1" (
								call :NSUTIL_DecRef "!_T.DR.FV!"
							)
						)
						set "!_T.DR.B!.Data.Value[!%%k!]="
						set "%%k="
					)
					set "!_T.DR.B!.Type="
					set "!_T.DR.B!.RefCnt="
					set "_T.DR.REF=1"
				)
			)
			rem clear meta slot
			set "!_T.DR.H!.Type="
			set "!_T.DR.H!.Target="
			set "!_T.DR.H!.RC="
			set "_T.DR.B="
			set "_T.DR.REF="
			set "_T.DR.FV="
			set "_T.DR.FS="
			set "_T.DR.FM="
			set "_T.DR.BR="
		)
		set "_T.DR.H="
		goto :NSUTIL_DrainDestroy_Chk
	)
%-|%

:NSUTIL_FreeRC *NS
	rem Free(RCMODE)=DecRef: RC-1; real destroy only at zero; then drain queue.
	%&% _G.RET _T.RF.RetBackup
	call :NSUTIL_DecRef "%~1"
	if defined _G.DESTROY.C call :NSUTIL_DrainDestroy
	%&% _T.RF.RetBackup _G.RET
	set "_T.RF.RetBackup="
%-|%

:NSUTIL_CloneBodyRC *NS *NewNS
	rem CloneBody(RCMODE): alloc new body, fields become shared handle refs (+IncRef),
	rem replaces CloneMeta deep-copy wrapper (no wrapper growth per Set).
	set /a "_G.NSP += 1"
	set "_T.C2.NewBody=_G.NS[!_G.NSP!]"
	set "!_T.C2.NewBody!.Type=NSBody"
	set "!_T.C2.NewBody!.RefCnt=1"
	( set "!%~1!.Data.Key" ) > "%TEMP%\mal_c_!_G.LEVEL!.txt" 2>nul
	for /f "usebackq delims==" %%a in ("%TEMP%\mal_c_!_G.LEVEL!.txt") do (
		set "!_T.C2.NewBody!.Data.Key[!%%a!]=!%%a!"
		call set "_T.C2.FV=%%!%~1!.Data.Value[!%%a!]%%"
		set "_T.C2.FS=!_T.C2.FV:~0,6!"
		if "!_T.C2.FS!" == "_G.NS[" (
			call :NSUTIL_IsValidNS "!_T.C2.FV!" %->% _T.C2.FM
			if "!_T.C2.FM!" == "1" (
				call :NSUTIL_IncRef "!_T.C2.FV!"
			)
		)
		set "!_T.C2.NewBody!.Data.Value[!%%a!]=!_T.C2.FV!"
	)
	set "_T.C2.FS="
	set "_T.C2.FM="
	%&% "_T.C2.NewBody" "%~2"
%-|%

:NSUTIL_SetRC *NS Field *Val
	rem Set(RCMODE): 1) COW clone if shared body (+1) 2) overwrite old field DecRef
	rem 3) store raw handle +IncRef (no wrapper) 4) drain queue if any enqueued.
	>&2 echo [SRC] ent NS=%~1 F=%~2 V=%~3
	set "_T.S2.T=%~1"
	set "_T.S2.F=%~2"
	set "_T.S2.V=%~3"

	if defined %~1.Target (
		set "_T.S2.NSBody=!%~1.Target!"
	) else (
		call set "_T.S2.NSBody=%%!%~1!.Target%%"
	)

	rem same-value short-circuit (#3 semantic preserved: unchanged -> return)
	call :NSUTIL_HasField "%~1" "%~2" %->% "_T.S2.HasField"
	if "!_T.S2.HasField!" == "1" (
		call set "_T.S2.CurVal=%%!_T.S2.NSBody!.Data.Value[%~2]%%"
		if "!_T.S2.CurVal!" == "!_T.S2.V!" %-|%
	)

	rem COW: clone only when body is shared
	call set "_T.S2.RefCnt=%%!_T.S2.NSBody!.RefCnt%%"
	if !_T.S2.RefCnt! gtr 1 (
		set /a "!_T.S2.NSBody!.RefCnt -= 1"
		call :NSUTIL_CloneBodyRC "_T.S2.NSBody" "_T.S2.NewBody"
		set "_T.S2.NSBody=!_T.S2.NewBody!"
		if defined %~1.Target (
			set "%~1.Target=!_T.S2.NewBody!"
		) else (
			call set "%~1.Target=%%!_T.S2.NewBody!%%"
		)
	)

	rem overwrite old value: if NS, DecRef (release old ref)
	if "!_T.S2.HasField!" == "1" (
		call set "_T.S2.CurVal=%%!_T.S2.NSBody!.Data.Value[%~2]%%"
		call :NSUTIL_IsValidNS "!_T.S2.CurVal!" %->% "_T.S2.IsMeta"
		if "!_T.S2.IsMeta!" == "1" (
			call :NSUTIL_DecRef "!_T.S2.CurVal!"
		)
	)

	rem store new value
	set "!_T.S2.NSBody!.Data.Key[%~2]=%~2"
	>&2 echo [SRC] pre-ISNS V=!_T.S2.V!
	call :NSUTIL_IsValidNS "!_T.S2.V!" %->% "_T.S2.IsNS"
	>&2 echo [SRC] post-ISNS IsNS=!_T.S2.IsNS! IsMeta=!_T.S2.IsMeta!
	if "!_T.S2.IsNS!" == "1" (
		rem resolve new value to raw handle and IncRef
		if defined %~3.Target (
			set "_T.S2.VH=%~3"
		) else (
			call set "_T.S2.VH=%%!%~3!%%"
			if not defined _T.S2.VH set "_T.S2.VH=%~3"
			if "!_T.S2.VH:~0,6!" == "_G.LEVEL[" call set "_T.S2.VH=%%!_T.S2.VH!%%"
		)
		if not "!_T.S2.VH:~0,6!" == "_G.NS[" set "_T.S2.VH=%~3"
		set "!_T.S2.NSBody!.Data.Value[%~2]=!_T.S2.VH!"
		call :NSUTIL_IncRef "!_T.S2.VH!"
	) else (
		rem Round6B: V must be staged via a delayed-expansion variable:
		rem literal ")" "]" "}" inside set "name=V" is still parsed as block-end
		rem when the set line itself sits inside a nested for/if compound block.
		set "_T.S2.V2=!_T.S2.V!"
		set "!_T.S2.NSBody!.Data.Value[%~2]=!_T.S2.V2!"
	)
if defined _G.DESTROY.C call :NSUTIL_DrainDestroy
	set "_T.S2.CurVal="
	set "_T.S2.VH="
	>&2 echo [SRC] ret
	%-|%

:NSUTIL_SetDirectRC *NS Field *Val
	rem SetDirect(RCMODE): write-through shared env (def! semantic), no COW; overwrite DecRef + store raw handle +IncRef.
	set "_T.SD2.T=%~1"
	set "_T.SD2.F=%~2"
	set "_T.SD2.V=%~3"

	if defined %~1.Target (
		set "_T.SD2.NSBody=!%~1.Target!"
	) else (
		call set "_T.SD2.NSBody=%%!%~1!.Target%%"
	)

	rem overwrite old value DecRef
	call :NSUTIL_HasField "%~1" "%~2" %->% "_T.SD2.HasField"
	if "!_T.SD2.HasField!" == "1" (
		call set "_T.SD2.CurVal=%%!_T.SD2.NSBody!.Data.Value[%~2]%%"
		call :NSUTIL_IsValidNS "!_T.SD2.CurVal!" %->% "_T.SD2.IsMeta"
		if "!_T.SD2.IsMeta!" == "1" (
			call :NSUTIL_DecRef "!_T.SD2.CurVal!"
		)
	)

	rem store new value (self env, no COW)
	set "!_T.SD2.NSBody!.Data.Key[%~2]=%~2"
	call :NSUTIL_IsValidNS "!_T.SD2.V!" %->% "_T.SD2.IsNS"
	if "!_T.SD2.IsNS!" == "1" (
		if defined %~3.Target (
			set "_T.SD2.VH=%~3"
		) else (
			call set "_T.SD2.VH=%%!%~3!%%"
			if not defined _T.SD2.VH set "_T.SD2.VH=%~3"
			if "!_T.SD2.VH:~0,6!" == "_G.LEVEL[" call set "_T.SD2.VH=%%!_T.SD2.VH!%%"
		)
		if not "!_T.SD2.VH:~0,6!" == "_G.NS[" set "_T.SD2.VH=%~3"
		set "!_T.SD2.NSBody!.Data.Value[%~2]=!_T.SD2.VH!"
		call :NSUTIL_IncRef "!_T.SD2.VH!"
	) else (
		set "!_T.SD2.NSBody!.Data.Value[%~2]=!_T.SD2.V!"
	)
	if defined _G.DESTROY.C call :NSUTIL_DrainDestroy
	set "_T.SD2.CurVal="
	set "_T.SD2.VH="
%-|%
