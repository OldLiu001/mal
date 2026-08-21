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
			call UTIL :UTIL_Init "%~1"
		)

		set "_G.NSUTIL=%~n0"

		set /a "_G.NSP = 0"

		if defined _G.PACKED (
			set "{n=call :NSUTIL_New"
			set "{c=call :NSUTIL_Clone"
			set "{g=call :NSUTIL_Get"
			set "{s=call :NSUTIL_Set"
		) else (
			set "{n=call NSUTIL :NSUTIL_New"
			set "{c=call NSUTIL :NSUTIL_Clone"
			set "{g=call NSUTIL :NSUTIL_Get"
			set "{s=call NSUTIL :NSUTIL_Set"
		)
	)
%-|%

:NSUTIL_New *NSVar
	for %%. in (_T.NW.) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
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
		
		set "_G.LEVEL[!_G.LEVEL!][!%%.NSMeta!]=!%%.NSMeta!"
		
		set "%~1=!%%.NSMeta!"
	)
%-|%

:NSUTIL_IsNSMeta *NS -> Bool
	for %%. in (_T.CL.) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		set "%%.T=%~1"
		call set "%%.V=%%!%%.T!%%"
		if not defined %%.V set "%%.V=!%%.T!"
		call set "%%.Type=%%!%%.V!.Type%%"
		if /i "!%%.Type!" == "NSMeta" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsNSBody *NS -> Bool
	for %%. in (_T.GET.) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		set "%%.T=%~1"
		call set "%%.V=%%!%%.T!%%"
		if not defined %%.V set "%%.V=!%%.T!"
		call set "%%.Type=%%!%%.V!.Type%%"
		if /i "!%%.Type!" == "NSBody" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsValidNS *NS -> Bool
	for %%. in (_T.SET.) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

		set "%%.T=%~1"
		call set "%%.V=%%!%%.T!%%"
		if not defined %%.V set "%%.V=!%%.T!"
		call set "%%.Type=%%!%%.V!.Type%%"
		if /i "!%%.Type!" neq "NSMeta" (
			set "%%.Res=0"
			%<-% "%%.Res"
			%-|%
		)
		call set "%%.Target=%%!%%.V!.Target%%"
		if defined %%.Target (
			call set "%%.T2Type=%%!%%.Target!.Type%%"
			if /i "!%%.T2Type!" == "NSBody" (
				set "%%.Res=1"
			) else (
				set "%%.Res=0"
			)
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_AssertValidNS *NS
	for %%. in (_T.V.) do (

		set "%%.T=%~1"
		%_G.DOTHIS% %-|%
		if not defined _G.NSUTIL (
			>&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsValidNS "!%%.T!" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_AssertValidNSBody *NS
	for %%. in (_T.IM.) do (

		set "%%.T=%~1"
		%_G.DOTHIS% %-|%
		if not defined _G.NSUTIL (
			>&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsNSBody "!%%.T!" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_Clone *From *To
	for %%. in (_T.IB.) do (

		set "%%.T=%~1"
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
			set "%%.NSBody=!%~1.Target!"
		) else (
			%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
			%&% "!%~1!.Target" "%%.NSBody"
		)
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"

		set "_G.LEVEL[!_G.LEVEL!][!%~2!]=!%~2!"
	)
%-|%

:NSUTIL_CloneMeta *From *To
	for %%. in (_T.CM.) do (

		set "%%.T=%~1"
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
			set "%%.NSBody=!%~1.Target!"
		) else (
			%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
			%&% "!%~1!.Target" "%%.NSBody"
		)
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"
	)
%-|%

:NSUTIL_HasField *NS -> Bool
	for %%. in (_T.HF.) do (

		set "%%.T=%~1"
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."

		%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

		if defined %~1.Target (
			set "%%.NSBody=!%~1.Target!"
		) else (
			%&% "!%~1!.Target" "%%.NSBody"
		)
		if defined !%%.NSBody!.Data.Key[%~2] (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_Get *NS Field *Val
	for %%. in (_T.AV.) do (

		set "%%.T=%~1"
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'Field' undefined."
		%_G.SKIPTHIS% if "%~3" == "" %?|% "'Val' undefined."

		%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

		call NSUTIL :NSUTIL_HasField "%~1" "%~2" %->% %%.Res

		if defined %~1.Target (
			set "%%.NSBody=!%~1.Target!"
		) else (
			%&% "!%~1!.Target" "%%.NSBody"
		)
		set "%%.ValName=!%%.NSBody!.Data.Value[%~2]"
		call :NSUTIL_IndirectGet "%%.ValName" "%~3"
	)
%-|%

:NSUTIL_IndirectGet *VarName *Out
	call set "%~2=%%!%~1!%%"
	exit /b 0
%-|%

:NSUTIL_Free *NS
	for %%. in (_T.FR.) do (

		set "%%.T=%~1"
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )

		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."

				%&% _G.RET %%.RetBackup

		%_G.SKIPTHIS% %{% NSUTIL AssertValidNS "%~1" %}%

		if defined %~1.Target (
			set "%%.NSBody=!%~1.Target!"
			set "%~1.Type="
			set "%~1.Target="
		) else (
			%&% "!%~1!.Target" "%%.NSBody"
			set "!%~1!.Type="
			set "!%~1!.Target="
		)

		call NSUTIL :NSUTIL_FreeNSBody "%%.NSBody"

		%&% %%.RetBackup _G.RET
	)
%-|%

:NSUTIL_FreeNSBody *NS
	for %%. in (_T.FB.) do (

		set "%%.T=%~1"
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		
		%_G.SKIPTHIS% %{% NSUTIL AssertValidNSBody "%~1" %}%

		%&% "!%~1!.RefCnt" "%%.RefCnt"

		if !%%.RefCnt! gtr 1 (
			set /a "!%~1!.RefCnt -= 1"
		) else (
			if !%%.RefCnt! lss 1 (
				%?|% "double free detected."
			)

			set "!%~1!.Type="
			set "!%~1!.RefCnt="

			( set "!%~1!.Data.Key" ) > "%TEMP%\mal_f.txt" 2>nul
			for /f "usebackq delims==" %%a in ("%TEMP%\mal_f.txt") do (
				set "!%~1!.Data.Value[!%%a!]="
				set "%%a="
			)
		)
	)
%-|%

:NSUTIL_CloneBody *NS *NewNS
	for %%. in (_T.CB.) do (
		%_G.SKIPTHIS% if not defined _G.NSUTIL (
		%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
		%_G.SKIPTHIS% 	2>con >&2 pause
		%_G.SKIPTHIS% 	exit 1
		%_G.SKIPTHIS% )
	
		%_G.SKIPTHIS% if "%~1" == "" %?|% "'NS' undefined."
		%_G.SKIPTHIS% if "%~2" == "" %?|% "'NewNS' undefined."

		%_G.SKIPTHIS% %{% NSUTIL AssertValidNSBody "%~1" %}%

		set /a "_G.NSP += 1"
		set "%%.NewBody=_G.NS[!_G.NSP!]"
		set "!%%.NewBody!.Type=NSBody"
		set "!%%.NewBody!.RefCnt=1"

		( set "!%~1!.Data.Key" ) > "%TEMP%\mal_f.txt" 2>nul
		for /f "usebackq delims==" %%a in ("%TEMP%\mal_f.txt") do (
			set "!%%.NewBody!.Data.Key[!%%a!]=!%%a!"

			call NSUTIL :NSUTIL_IsNSMeta "!%~1!.Data.Value[!%%a!]" %->% %%.IsMeta
			if "!%%.IsMeta!" == "1" (
				call NSUTIL :NSUTIL_CloneMeta "!%~1!.Data.Value[!%%a!]" "!%%.NewBody!.Data.Value[!%%a!]"%
			) else (
				%&% "!%~1!.Data.Value[!%%a!]" "!%%.NewBody!.Data.Value[!%%a!]"
			)
		)

		%&% "%%.NewBody" "%~2"
	)
%-|%

:NSUTIL_Set *NS Field *Val
	for %%. in (_T.AB.) do (

		set "%%.T=%~1"
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
			set "%%.NSBody=!%~1.Target!"
		) else (
			%&% "!%~1!.Target" "%%.NSBody"
		)

		%&% "!%%.NSBody!.RefCnt" "%%.RefCnt"
		if !%%.RefCnt! gtr 1 (
			set /a "!%%.NSBody!.RefCnt -= 1"
			call NSUTIL :NSUTIL_CloneBody "%%.NSBody" "%%.NewBody"
			%&% "%%.NewBody" "%%.NSBody"
			if defined %~1.Target (
				set "!%~1!.Target=!%%.NewBody!"
			) else (
				%&% "%%.NewBody" "!%~1!.Target"
			)
		)

		set "%%.V=%~3"

		call NSUTIL :NSUTIL_HasField "%~1" "%~2" %->% "%%.HasField"
		if "!%%.HasField!" == "1" (
			%&% "!%%.NSBody!.Data.Value[%~2]" %%.OldVal
			if "!%%.OldVal!" == "!%%.V!" (
				%-|%
			)
			%{% NSUTIL IsValidNS "!%%.OldVal!" %}% %->% "%%.IsMeta"
			if "!%%.IsMeta!" == "1" (
				call NSUTIL :NSUTIL_Free "%%.OldVal"
			)
		)

		set "!%%.NSBody!.Data.Key[%~2]=%~2"
		call NSUTIL :NSUTIL_IsValidNS "!%%.V!" %->% "%%.IsNS"
		if "!%%.IsNS!" == "1" (
			call NSUTIL :NSUTIL_CloneMeta "!%%.V!" "!%%.NSBody!.Data.Value[%~2]"
		) else (
			set "!%%.NSBody!.Data.Value[%~2]=!%%.V!"
		)
	)
%-|%

