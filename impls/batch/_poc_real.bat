@echo off
setlocal ENABLEDELAYEDEXPANSION
set _L[0].Reader=NS9
for %%q in (_L[0].) do (
    echo PRE   reader=[!%%qReader!]   (expect NS9)
    call :CALLEE
    echo MID   reader=[!%%qReader!]   (expect NS9: survives nested call)
    call :SETNS %%qReader NS77
    echo POST  reader=[!%%qReader!]   (expect NS77: arg passed & assigned)
    call :SETVIA "%%qReader" NS88
    echo POST2 reader=[!%%qReader!]   (expect NS88)
)
exit /b 0
:CALLEE
    set "unused=1"
    ( set "unused" ) > "%TEMP%\poc_c.txt" 2>nul
    for /f "usebackq delims==" %%a in ("%TEMP%\poc_c.txt") do set "%%a="
exit /b 0
:SETNS
    set "%~1=%~2"
exit /b 0
:SETVIA
    set "%~1=%~2"
exit /b 0