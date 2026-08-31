@echo off
setlocal ENABLEDELAYEDEXPANSION
set "arg=(1 2 3)"
echo T1: for /f with parens in command string
for /f "tokens=1,2,*" %%a in ('echo.READER ReadString "!arg!"') do (
	echo a=%%a b=%%b c=%%c
)
echo T2: for /f with paren value via variable
set "cmdline=READER ReadString "!arg!""
for /f "tokens=1,2,*" %%a in ('echo.!cmdline!') do (
	echo a=%%a b=%%b c=%%c
)
echo T3: nested call inside block with parens
for /l %%x in (1 1 1) do (
	call :TARGET "!arg!"
)
echo done
exit /b 0
:TARGET
echo got: %~1
exit /b 0
