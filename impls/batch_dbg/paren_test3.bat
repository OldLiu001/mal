@echo off
setlocal ENABLEDELAYEDEXPANSION
echo T1: top-level for/f command string with quoted paren
for /f "tokens=1,*" %%a in ('echo.NSUTIL Set "x" ")"') do (
	echo a=%%a b=%%b
)
echo T2: same inside an outer block
for /l %%x in (1 1 1) do (
	for /f "tokens=1,*" %%a in ('echo.NSUTIL Set "x" ")"') do (
		echo a=%%a b=%%b
	)
)
echo T3: with ( 
for /f "tokens=1,*" %%a in ('echo.NSUTIL Set "x" "("') do (
	echo a=%%a b=%%b
)
echo done
exit /b 0
