@echo off
setlocal ENABLEDELAYEDEXPANSION
set /a _G.LEVEL=0
set /a _G.NSP=0
set "_G.NS[1]=_G.NS[1]"
set /a _G.NSMAX=8000

rem sim macros
set "{n=call :NSUTIL_New"
set "{g=call :NSUTIL_Get"
set "{s=call :NSUTIL_Set"
set "{P=call :UTIL_Invoke"
set "{%=call :UTIL_Invoke "
set "%}=%"

:NSUTIL_New *NSVar
    if "%~1" == "" (echo GUARD New empty & exit /b 1)
    set /a _G.NSP += 1
    set "%~1=_G.NS[!_G.NSP!]"
exit /b 0

:NSUTIL_Get *NS *Field *To
    set "%~3="
    call set "%~3=%%%~1.%~2%%"
exit /b 0

:NSUTIL_Set *NS *Field *Val
    set "%~1.%~2=%~3"
exit /b 0

:UTIL_Invoke Mod Fn ...
    rem simulate nested cross-call that touches a DIFFERENT for-var letter
    call :TOKENIZE_SIM "%~4" "%~5"
exit /b 0

:TOKENIZE_SIM _Str _R
for %%. in (_T.[xor].) do (
    set "%%z.touch=1"
)
exit /b 0

:MAIN
for %%. in (_L[0].) do (
    set "%%.Str=abc"
    %{n% %%.R %}
    %{P% TOKENIZE "!%%.Str!" "!%%.R!" %}
    echo READBACK=%%.R  value=!%%.R!
)
exit /b 0