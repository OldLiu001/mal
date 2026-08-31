@echo off
setlocal ENABLEDELAYEDEXPANSION
set /a _G.LEVEL=0
set _G.NSUTIL=1
set /a _G.NSP=0

:NSUTIL_New
set /a "_G.NSP += 1"
set "_T.NW.NSBody=_G.NS[!_G.NSP!]"
set "!_T.NW.NSBody!.Type=NSBody"
set /a "_G.NSP += 1"
set "_T.NW.NSMeta=_G.NS[!_G.NSP!]"
set "!_T.NW.NSMeta!.Type=NSMeta"
set "!_T.NW.NSBody!.RefCnt=1"
set "!_T.NW.NSMeta!.Target=!_T.NW.NSBody!"
set "%~1=!_T.NW.NSMeta!"
exit /b 0

:MAIN
for %%. in (_L[!_G.LEVEL!].) do (
    echo A defined=!%%.R!
    call :NSUTIL_New %%.R
    echo B value=!%%.R!
    if "!%%.R!" == "" (echo RESULT=FAIL) else (echo RESULT=PASS)
)
exit /b 0

call :MAIN