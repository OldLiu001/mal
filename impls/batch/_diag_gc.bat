@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step4_if_fn_do

%{% TYPES NewMalMap %}% %->% _G.ENV
%{% MAIN RegisterBuiltins _G.ENV %}%
echo ENV=[!_G.ENV!]
call set "_T.T=%%!_G.ENV!.Type%%"
echo ENV.Type=[!_T.T!]
call set "_T.TG=%%!_G.ENV!.Target%%"
echo ENV.Target=[!_T.TG!]

echo --- now do a simple REP call (level 1) ---
set "_T.RD.Str=(+ 1 2)"
%{% MAIN REP _T.RD.Str %}%
echo REP returned

call set "_T.T2=%%!_G.ENV!.Type%%"
echo ENV.Type after REP=[!_T.T2!]
call set "_T.TG2=%%!_G.ENV!.Target%%"
echo ENV.Target after REP=[!_T.TG2!]
call set "_T.RC=%%!_T.TG2!.RefCnt%%"
echo ENV Body RefCnt=[!_T.RC!]
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
