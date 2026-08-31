@echo off
setlocal ENABLEDELAYEDEXPANSION
set "arg=(1 2 3)"
echo test1: pass parens via echo.* and for /f
for /f "tokens=1,2,*" %%a in ('echo.READER Tokenize "!arg!"') do (
	echo a=%%a b=%%b c=%%c
)
echo test3: direct call with parens arg
call :TARGET "(1 2 3)"
echo done
exit /b 0
:TARGET
echo got: %~1
exit /b 0
