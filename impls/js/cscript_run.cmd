@echo off
rem cscript_run.cmd - Launch cscript with mal js bundled step
rem Used by runtest.py which appends .cmd to args[0]
rem Usage: cscript_run.cmd <step.js> [args...]

setlocal
set "IMPL_DIR=%~dp0"
set "SCRIPT=%IMPL_DIR%dist\%~1"
shift

cscript //Nologo //E:JScript "%SCRIPT%" %1 %2 %3 %4 %5 %6 %7 %8 %9
