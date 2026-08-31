@echo off
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step4_if_fn_do

%{% TYPES NewMalMap %}% %->% _G.ENV
%{% MAIN RegisterBuiltins _G.ENV %}%
echo ENV=[!_G.ENV!]

echo --- Clone ENV (RefCnt -> 2) ---
%{c% _G.ENV _T.ENV2 %}%
echo ENV2=[!_T.ENV2!]

echo --- manual COW simulation ---
set "_T.AB.T=_G.ENV"
if defined !_T.AB.T!.Target (
	set "_T.AB.NSBody=!!_T.AB.T!.Target!"
) else (
	call set "_T.AB.NSBody=%%!_T.AB.T!.Target%%"
)
echo NSBody=[!_T.AB.NSBody!]
call set "_T.AB.RefCnt=%%!_T.AB.NSBody!.RefCnt%%"
echo RefCnt=[!_T.AB.RefCnt!]
if !_T.AB.RefCnt! gtr 1 (
	set /a "!_T.AB.NSBody!.RefCnt -= 1"
	echo after decrement RefCnt
	call :NSUTIL_CloneBody "_T.AB.NSBody" "_T.AB.NewBody"
	echo after CloneBody: NewBody=[!_T.AB.NewBody!]
	call set "_T.AB.NSBody=%%!_T.AB.NewBody!%%"
	echo NSBody now=[!_T.AB.NSBody!]
	if defined !_T.AB.T!.Target (
		set "!_T.AB.T!.Target=!_T.AB.NewBody!"
		echo set Target to [!_T.AB.NewBody!]
	) else (
		echo else branch
	)
)
call set "_T.TG=%%!_G.ENV!.Target%%"
echo ENV Target=[!_T.TG!]
call set "_T.RC=%%!_T.TG!.RefCnt%%"
echo New Body RefCnt=[!_T.RC!]
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
