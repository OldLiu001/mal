@echo off
setlocal ENABLEDELAYEDEXPANSION
echo T1: quoted echo-pipe inside block
for /l %%x in (1 1 1) do (
	echo."(1 2 3)"| call WRITEALL
)
echo T2: unquoted echo-pipe inside block
for /l %%x in (1 1 1) do (
	echo.(1 2 3)| call WRITEALL
)
echo T3: echo quoted paren no pipe
for /l %%x in (1 1 1) do (
	echo."(1 2 3)"
)
echo done
exit /b 0