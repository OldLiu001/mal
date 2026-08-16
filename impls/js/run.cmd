@echo off
rem run.cmd - Launch mal js implementation via cscript (JScript)
rem Usage: run.cmd [stepN_xxx] [args...]
rem   run.cmd                 -> runs stepA_mal.js
rem   run.cmd step1_read_print -> runs step1_read_print.js
rem   run.cmd stepA_mal test.mal -> runs stepA_mal.js with test.mal as argument

setlocal
set "IMPL_DIR=%~dp0"

rem Default step
set "STEP=%~1"
if "%STEP%"=="" set "STEP=stepA_mal"

rem Check if first arg starts with "step"
echo %STEP% | findstr /r "^step" >nul
if errorlevel 1 (
    rem First arg is not a step, use default
    set "STEP=stepA_mal"
) else (
    rem Shift past the step argument
    shift
)

rem Build the bundled single file if it doesn't exist
if not exist "%IMPL_DIR%\dist\%STEP%.js" (
    bash "%IMPL_DIR%\build.sh" "%STEP%"
)

rem Run with cscript
cscript //Nologo //E:JScript "%IMPL_DIR%\dist\%STEP%.js" %2 %3 %4 %5 %6 %7 %8 %9
