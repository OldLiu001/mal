@echo off
setlocal ENABLEDELAYEDEXPANSION
set _L[0].Reader=NS1
for %%. in (_L[0].) do (
    echo PASS1 [%%TOT] call with NAME arg
    call :PRINTNAME %%.Reader
    echo PASS2 after-call, read value via loopvar: [!%%.Reader!]
    call :PRINTVAL "!%%.Reader!"
    echo PASS3 after-call2, read value via loopvar: [!%%.Reader!]
)
exit /b 0
:PRINTNAME
    echo   NAMEARG=[%~1]
exit /b 0
:PRINTVAL
    echo   VALARG=[%~1]
exit /b 0