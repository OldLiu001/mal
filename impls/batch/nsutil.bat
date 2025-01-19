@echo off
%_G.DOTHIS% call %*
%_G.DOTHIS% exit /b 0
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

:NSUTIL_Init Main
	if not defined _G.NSUTIL (
		if defined _G.PACKED (
			call :UTIL_Init "%~1"
		) else (
			call UTIL :UTIL_Init "%~1"
		)

		set "_G.NSUTIL=%~n0"

		set /a "_G.NSP = 0"

		set "{n=!{! NSUTIL New"
		set "{c=!{! NSUTIL Clone"
		set "{g=!{! NSUTIL Get"
		set "{s=!{! NSUTIL Set"
	)
%-|%

:NSUTIL_New *NSVar
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
		
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NSVar' undefined."

		set /a "_G.NSP += 1"
		set "%%.NSBody=_G.NS[!_G.NSP!]"
		set "!%%.NSBody!.Type=NSBody"
		set /a "_G.NSP += 1"
		set "%%.NSMeta=_G.NS[!_G.NSP!]"
		set "!%%.NSMeta!.Type=NSMeta"

		set "!%%.NSBody!.RefCnt=1"
		set "!%%.NSMeta!.Target=!%%.NSBody!"
		
		set /a "%%.PrevLv = _G.LEVEL - 1"
		set "_G.LEVEL[!%%.PrevLv!][!%%.NSMeta!]=!%%.NSMeta!"
		
		set "%~1=!%%.NSMeta!"
	)
%-|%

:NSUTIL_IsNSMeta *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		%&% "!%~1!.Type" "%%.Type"
		if /i "!%%.Type!" == "NSMeta" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsNSBody *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		%&% "!%~1!.Type" "%%.Type"
		if /i "!%%.Type!" == "NSBody" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsValidNS *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		%{% NSUTIL IsNSMeta "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" (
			%<-% %%.Res
			%-|%
		)
		%{% NSUTIL IsNSBody "!%~1!.Target" %}% %->% %%.Res
		%<-% %%.Res
	)
%-|%

:NSUTIL_AssertValidNS *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.DOTHIS% %-|%
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsValidNS "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_AssertValidNSBody *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.DOTHIS% %-|%
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsNSBody "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_Clone *From *To
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'From' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'To' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].Type=NSMeta"
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "%%.NSBody"
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"

		set /a "%%.PrevLv = _G.LEVEL - 1"
		set "_G.LEVEL[!%%.PrevLv!][!%~2!]=!%~2!"
	)
%-|%

:NSUTIL_CloneMeta *From *To
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'From' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'To' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].Type=NSMeta"
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "%%.NSBody"
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"
	)
%-|%

:NSUTIL_HasField *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%&% "!%~1!.Target" "%%.NSBody"
		if defined !%%.NSBody!.Data.Key[%~2] (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_Get *NS Field *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
		%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%{% NSUTIL HasField "%~1" "%~2" %}% %->% %%.Res

		%&% "!%~1!.Target" "%%.NSBody"
		%&% "!%%.NSBody!.Data.Value[%~2]" "%~3"
		set "!%%.NSBody!.Data.Key[%~2]="
		set "!%%.NSBody!.Data.Value[%~2]="
	)
%-|%

:NSUTIL_Free *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		%&% _G.RET %%.RetBackup

		%{% NSUTIL AssertValidNS "%~1" %}%
	
		%&% !%~1!.Target %%.NSBody
		set "!%~1!.Type="
		set "!%~1!.Target="

		%{% NSUTIL FreeNSBody "%%.NSBody" %}%

		%&% %%.RetBackup _G.RET
	)
%-|%

:NSUTIL_FreeNSBody *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		
		%{% NSUTIL AssertValidNSBody "%~1" %}%

		%&% "!%~1!.RefCnt" "%%.RefCnt"

		if !%%.RefCnt! gtr 1 (
			set /a "!%~1!.RefCnt -= 1"
		) else (
			if !%%.RefCnt! lss 1 (
				%?|% "double free detected."
			)

			set "!%~1!.Type="
			set "!%~1!.RefCnt="

			for /f "delims==" %%a in (
				'set !%~1!.Data.Key 2^>nul'
			) do (
				%&% "!%~1!.Data.Value[!%%a!]" "%%.Var"
				set "!%~1!.Data.Value[!%%a!]="

				%{% NSUTIL IsNSMeta "%%.Var" %}% %->% "%%.IsMeta"
				if "!%%.IsMeta!" == "1" (
					%{% NSUTIL Free "%%.Var" %}%
				)
				set "%%a="
			)
		)
	)
%-|%

:NSUTIL_CloneBody *NS *NewNS
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'NewNS' undefined."

		%{% NSUTIL AssertValidNSBody "%~1" %}%

		set /a "_G.NSP += 1"
		set "%%.NewBody=_G.NS[!_G.NSP!]"
		set "!%%.NewBody!.Type=NSBody"
		set "!%%.NewBody!.RefCnt=1"

		for /f "delims==" %%a in (
			'set !%~1!.Data.Key 2^>nul'
		) do (
			set "!%%.NewBody!.Data.Key[%%a]=%%a"

			%{% NSUTIL IsNSMeta "!%~1!.Data.Value[%%a]" %}% %->% %%.IsMeta
			if "!%%.IsMeta!" == "1" (
				%{% NSUTIL CloneMeta "!%~1!.Data.Value[%%a]" "!%%.NewBody!.Data.Value[%%a]" %}%
			) else (
				%&% "!%~1!.Data.Value[%%a]" "!%%.NewBody!.Data.Value[%%a]"
			)
		)

		%&% "%%.NewBody" "%~2"
	)
%-|%

:NSUTIL_Set *NS Field *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
		%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%&% "!%~1!.Target" "%%.NSBody"

		%&% "!%%.NSBody!.RefCnt" "%%.RefCnt"
		if !%%.RefCnt! gtr 1 (
			set /a "!%%.NSBody!.RefCnt -= 1"
			%{% NSUTIL CloneBody "%%.NSBody" "%%.NewBody" %}%
			%&% "%%.NewBody" "%%.NSBody"
			%&% "%%.NewBody" "!%~1!.Target"
		)

		%{% NSUTIL HasField "%~1" "%~2" %}% %->% "%%.HasField"
		if "!%%.HasField!" == "1" (
			%&% "!%%.NSBody!.Data.Value[%~2]" %%.OldVal
			%{% NSUTIL IsValidNS "%%.OldVal" %}% %->% "%%.IsMeta"
			if "!%%.IsMeta!" == "1" (
				%{% NSUTIL Free "%%.OldVal" %}%
			)
		)

		set "!%%.NSBody!.Data.Key[%~2]=%~2"

		%{% NSUTIL IsValidNS "%~3" %}% %->% "%%.IsNS"
		if "!%%.IsNS!" == "1" (
			%{% NSUTIL CloneMeta "%~3" "!%%.NSBody!.Data.Value[%~2]" %}%
		) else (
			%&% "%~3" "!%%.NSBody!.Data.Value[%~2]"
		)
	)
%-|%

