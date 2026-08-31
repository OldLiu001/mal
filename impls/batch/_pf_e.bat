@echo off
setlocal ENABLEDELAYEDEXPANSION
set _pfvar=hello
for /l %%i in (1 1 5000) do set "_pfvar2=!x!"
exit /b 0
