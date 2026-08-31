@echo off
setlocal ENABLEDELAYEDEXPANSION
for /l %%i in (1 1 5000) do call _pf_child.bat :SUB
exit /b 0
