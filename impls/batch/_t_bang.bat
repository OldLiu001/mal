@echo off
setlocal ENABLEDELAYEDEXPANSION
set "v=abc!"
echo plain-literal=[%v%]
set "w=!v!"
echo via-delayed-var=[%w%]
setlocal DISABLEDELAYEDEXPANSION
set "p=abc!"
echo deladisabled-literal=[%p%]
set "q=!v!"
echo deldisabled-literal2=[%q%]
endlocal
rem call set preserves
set "v=abc!"
call set "r=%%v%%"
echo via-callset=[%r%]
exit /b 0