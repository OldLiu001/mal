@echo off
setlocal ENABLEDELAYEDEXPANSION
echo T1: call label with paren arg, for/f echo.* inside
call :SUB READER ReadString "(1 2 3)"
echo back
exit /b 0
:SUB
for /f "tokens=1,2,*" %%a in ('echo.%*') do (
	echo a=%%a b=%%b c=%%c
)
exit /b 0