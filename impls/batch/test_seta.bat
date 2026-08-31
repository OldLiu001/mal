@echo off
setlocal ENABLEDELAYEDEXPANSION
set "x=+"
echo T1
for /l %%i in (1 1 1) do (
	set /a "y = x"
	echo after1 y=!y!
)
echo T2
for /l %%i in (1 1 1) do (
	set /a "z = +"
	echo after2
)
echo DONE
exit /b 0