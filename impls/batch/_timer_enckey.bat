@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step4_if_fn_do
for /l %%i in (1 1 100) do (
    %{% MAIN EncKey + %}% %->% _T.E
)
echo done
exit /b 0

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
