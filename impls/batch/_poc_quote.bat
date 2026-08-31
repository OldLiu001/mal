@echo off
setlocal ENABLEDELAYEDEXPANSION
set _L[0].R=NS9
for %%q in (_L[0].) do (
    call :D  "%%q.R"
    echo QUOTED   arg?=%%q.R
    call :E  %%q.R
)
exit /b 0
:D
    echo D_QUOTED=[%~1]
exit /b 0
:E
    echo E_RAW=[%~1]
exit /b 0