@echo off
setlocal ENABLEDELAYEDEXPANSION
set /a _G.LEVEL=5
call :OUTER
echo DONE
exit /b 0

:OUTER
for %%. in (_L[!_G.LEVEL!].) do (
    set "%%.TokenPtr=HELLO"
    echo OUTER-before: read=!%%.TokenPtr!
    call :INNER
    echo OUTER-after:  read=!%%.TokenPtr!
    if "!%%.TokenPtr!" == "HELLO" (echo OUTER-MATCH survived) else (echo OUTER-CLOBBERED got=!%%.TokenPtr!)
)
exit /b 0

:INNER
for %%. in (_L[6].) do (
    set "%%.TokenPtr=INNER"
    echo   INNER set: val=!%%.TokenPtr!
)
exit /b 0