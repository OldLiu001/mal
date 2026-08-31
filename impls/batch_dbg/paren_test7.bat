@echo off
setlocal ENABLEDELAYEDEXPANSION
set "msg=unexpected token ')'. more"
echo T1: echo with paren inside block
for /l %%x in (1 1 1) do (
	echo.!msg!
)
echo T2: echo with apostrophe+paren
for /l %%x in (1 1 1) do (
	echo.unexpected token ')'
)
echo T3: set /p style
for /l %%x in (1 1 1) do (
	<nul set /p "=!msg!"
)
echo.
echo done
exit /b 0