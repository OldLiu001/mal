@echo off
setlocal ENABLEDELAYEDEXPANSION
for /l %%i in (1 1 5000) do (
  ( set _pfvar ) > %TEMP%\_pf_tmp.txt 2>nul
  for /f "usebackq delims==" %%a in ("%TEMP%\_pf_tmp.txt") do set "%%a="
)
exit /b 0
