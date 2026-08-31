@echo off
setlocal ENABLEDELAYEDEXPANSION
:SUB
set /a x += 1
exit /b 0
for /l %%i in (1 1 5000) do call :SUB
exit /b 0
