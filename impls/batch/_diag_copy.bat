@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step4_if_fn_do

set "_T.SRC=hello"
set "_T.DST=before"
echo SRC=[!_T.SRC!] DST=[!_T.DST!]
%&% _T.SRC _T.DST
echo after copy: DST=[!_T.DST!]

echo --- test CloneBody directly ---
%{% TYPES NewMalMap %}% %->% _T.M1
%{s% _T.M1 F1 10 %}%
%{s% _T.M1 F2 20 %}%
call set "_T.B1=%%!_T.M1!.Target%%"
echo M1 Body=[!_T.B1!]
call NSUTIL :NSUTIL_CloneBody "_T.B1" _T.NEWBODY
echo NEWBODY=[!_T.NEWBODY!]
call set "_T.NBT=%%!_T.NEWBODY!.Type%%"
echo NEWBODY.Type=[!_T.NBT!]
call set "_T.F1=%%!_T.NEWBODY!.Data.Value[F1]%%"
echo NEWBODY.F1=[!_T.F1!]
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
