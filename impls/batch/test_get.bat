@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init %~n0
%{% MAIN Main %}%
%-|%
:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Obj %}
		%{s% %%.Obj Type TestObj %}
		%{s% %%.Obj Value 42 %}
		echo OBJ=!%%.Obj!
		%{g% "!%%.Obj!" Type %%.T1 %}
		echo MODE1 Type=!%%.T1!
		%{g% "%%.Obj" Type %%.T2 %}
		echo MODE2 Type=!%%.T2!
		%&% "!%%.Obj!.Type" %%.T3
		echo MODE3 Type=!%%.T3!
	)
%-|%