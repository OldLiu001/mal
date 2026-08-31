@echo off
setlocal ENABLEDELAYEDEXPANSION
set _L[0].R=NS9
set _G.LEVEL=0
set _G.LEVEL[0][NS9]=NS9
rem test: for-var %%q in a block that calls an in-file label running for/f %%a,
rem then reads %%q again.
for %%q in (_L[0].) do (
    set "%%q.R2=leaktest"
    call :CALLEE
    echo POST1   R=[!%%q.R!]  R2=[!%%q.R2!]   (expect NS9 / leaktest)
    call :CALLEE2 "%%q.R3"
    echo POST2   R3=[!%%q.R3!]  (expect via-arg)
)
exit /b 0
:CALLEE
    set "garbage=1"
    set "prefix_inside=1"
    ( set "prefix_inside" 2^>nul ) > "%TEMP%\poc_f.txt" 2>&1
    for /f "usebackq delims==" %%a in ("%TEMP%\poc_f.txt") do set "%%a="
    echo   callee for/f-done
exit /b 0
:CALLEE2
    set "%~1=via-arg"
exit /b 0