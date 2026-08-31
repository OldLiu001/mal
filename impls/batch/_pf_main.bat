@echo off
setlocal ENABLEDELAYEDEXPANSION
set mode=%1
set /a N=%2

if "%mode%"=="same" (
  set t0=%time%
)
rem use jscript/cscript? no; use %time% delta via cmd lacks ms arithmetic.
rem Instead measure in caller using python around it and echo marker.
echo READY_%mode%