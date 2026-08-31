@echo off
setlocal ENABLEDELAYEDEXPANSION
set "y=(1 2 3)"
echo T1: set literal paren inside block
for /l %%x in (1 1 1) do (
	set "a=)"
	set "b=(1 2 3)"
	echo a=!a! b=!b!
)
echo T2: set from delayed var
for /l %%x in (1 1 1) do (
	set "c=!y!"
	echo c=!c!
)
echo T3: call util-like line
for /l %%x in (1 1 1) do (
	call :INNER "(1 2 3)" & call :INNER2 _L[3].Mal
)
echo done
exit /b 0
:INNER
echo inner got %~1
exit /b 0
:INNER2
echo inner2 got %~1
exit /b 0