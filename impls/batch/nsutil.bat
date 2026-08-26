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

		rem 环境规模动态受限（readme §0 准则4）：默认阈值可被外部 `set _G.NSMAX=…`
		rem 覆盖以适配不同机器；超出即终止，防止环境膨胀击穿性能与稳定性。
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
	rem 弃用 .for-var 域：显式唯一命名 `_T.NW.` 前缀，同文件内不再依赖进程隔离。
	%_G.SKIPTHIS% if not defined _G.NSUTIL (
	%_G.SKIPTHIS% 	>&2 echo [%~n0] Fatal: NSUTIL not initialized.
	%_G.SKIPTHIS% 	2>con >&2 pause
	%_G.SKIPTHIS% 	exit 1
	%_G.SKIPTHIS% )
	
	%_G.SKIPTHIS% if "%~1" == "" %?|% "'NSVar' undefined."

	rem 环境规模动态受限：分配前校验，超限立即终止而非默默膨胀。
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
	rem 显式命名 `_T.CL.`（弃用 .for-var 域）
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
	rem 显式命名 `_T.GET.`（弃用 .for-var 域）
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
	rem 显式命名 `_T.SET.`（弃用 .for-var 域）
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
	rem 显式命名 `_T.V.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.IM.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.IB.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.CM.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.HF.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.AV.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.FR.`（弃用 .for-var 域）

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
	rem 显式命名 `_T.FB.`（弃用 .for-var 域，内嵌 for /f %%a 保留）

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
	rem 显式命名 `_T.CB.`（弃用 .for-var 域，内嵌 for /f %%a 保留）
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
	rem 显式命名 `_T.AB.`（弃用 .for-var 域）

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

	rem 收窄 COW 触发面（#3）：同值短路前置——在深拷贝之前判等，值未变时直接返回，
	rem 避免无谓的 CloneBody 全字段深拷贝。Free 步随后重新读当前字段值，保持原语义。
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
	rem 环境直写（#step4 递归修复）：def! 修改共享环境时绕过 COW，
	rem 保持 MAL 引用语义——所有捕获该环境的闭包都能看到新绑定。
	rem 显式命名 `_T.SD.`（弃用 .for-var 域）

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

