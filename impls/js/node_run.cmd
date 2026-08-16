@echo off
rem node_run.cmd - Launch node with mal js step
rem Used by runtest.py which appends .cmd to args[0]
rem Usage: node_run.cmd <step.js> [args...]

setlocal
set "NODE_EXE=C:\AutoClaw\resources\node\node.exe"
set "IMPL_DIR=%~dp0"
set "SCRIPT=%IMPL_DIR%%~1"
shift

"%NODE_EXE%" "%SCRIPT%" %1 %2 %3 %4 %5 %6 %7 %8 %9
