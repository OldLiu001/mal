@echo off
setlocal enabledelayedexpansion

rem Test 1: call with ")" inside if block
echo Test 1: call with quoted paren
if 1 == 1 (
    call :MyFunc "hello" ")"
    echo After call
)
echo Done test 1

rem Test 2: call with ")" via variable
echo Test 2: call with variable
set "MYVAR=)"
if 1 == 1 (
    call :MyFunc "hello" "!MYVAR!"
    echo After call
)
echo Done test 2

goto :eof

:MyFunc
echo MyFunc arg1=%~1 arg2=%~2
set "STORED=%~2"
echo Stored=!STORED!
goto :eof
