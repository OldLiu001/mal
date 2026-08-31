@echo off
setlocal ENABLEDELAYEDEXPANSION
echo Star=[%*]
call :sub %*
echo After call
goto :eof

:sub
echo In sub: args=[%*] arg1=[%~1] arg2=[%~2] arg3=[%~3]
goto :eof
