@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step4_if_fn_do

%{% TYPES NewMalMap %}% %->% _G.ENV
%{% MAIN RegisterBuiltins _G.ENV %}%
echo ENV=[!_G.ENV!]

echo --- REP (fn* (a) (+ a 1)) creates closure ---
set "_T.RD.Str=(fn* (a) (+ a 1))"
%{% MAIN REP _T.RD.Str %}%
echo REP returned

call set "_T.TG=%%!_G.ENV!.Target%%"
call set "_T.RC=%%!_T.TG!.RefCnt%%"
echo ENV Body RefCnt after closure=[!_T.RC!]

echo --- REP (def! f 5) triggers COW ---
set "_T.RD.Str=(def! f 5)"
%{% MAIN REP _T.RD.Str %}%
echo REP returned

call set "_T.TG2=%%!_G.ENV!.Target%%"
echo ENV Target now=[!_T.TG2!]
call set "_T.RC2=%%!_T.TG2!.RefCnt%%"
echo ENV Body RefCnt now=[!_T.RC2!]
call set "_T.FCNT=%%!_T.TG2!.Data.Value[Item[f0].Count]%%"
echo Item[f0].Count=[!_T.FCNT!]
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
