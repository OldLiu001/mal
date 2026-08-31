@echo off
setlocal ENABLEDELAYEDEXPANSION
for /l %%i in (1 1 5000) do (
  for /f "delims==" %%a in ('set _pfvar') do set "%%a="
)
exit /b 0
