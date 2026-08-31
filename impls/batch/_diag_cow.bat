@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step4_if_fn_do

%{% TYPES NewMalMap %}% %->% _G.ENV
%{% MAIN RegisterBuiltins _G.ENV %}%
echo ENV=[!_G.ENV!]
call set "_T.BODY=%%!_G.ENV!.Target%%"
echo BODY=[!_T.BODY!]
call set "_T.RC=%%!_T.BODY!.RefCnt%%"
echo RefCnt before=[!_T.RC!]

echo --- CloneMeta ENV (simulate closure capture) ---
%{% NSUTIL CloneMeta _G.ENV _T.ENV2 %}%
echo ENV2=[!_T.ENV2!]
call set "_T.RC2=%%!_T.BODY!.RefCnt%%"
echo RefCnt after clone=[!_T.RC2!]

echo --- Now Set a field on ENV (triggers COW) ---
%{s% _G.ENV TestField 42 %}%
echo Set returned rc=%errorlevel%
call set "_T.RC3=%%!_T.BODY!.RefCnt%%"
echo RefCnt after set=[!_T.RC3!]
call set "_T.V=%%!_G.ENV!.Target%%"
echo ENV Target now=[!_T.V!]
call set "_T.TF=%%!_T.V!.Data.Value[TestField]%%"
echo TestField=[!_T.TF!]
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
