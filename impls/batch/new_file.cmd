@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)



set _ & (set | find /C /V "") & pause<nul
%{% MAIN TEST3 %}%
set _ & (set | find /C /V "") & pause
%-|%


:MAIN_TEST
	for %%. in (_L[!_G.LEVEL!].) do (
		%{#n% %%.A %}%
		set %%.B=3

		set %%.B2=30
		%{#s% %%.A k %%.B %}%
		%{#s% %%.A k2 %%.B %}%
		%{#s% %%.A k3 %%.B %}%
		%{#g% %%.A k  %%.R %}%


		%{#s% %%.A k2 %%.B2 %}%

		%{#n% %%.o %}%
		%{#s% %%.A o1 %%.o %}%

		%{#s% %%.A k3 %%.o %}%

		%{#s% %%.A o1 %%.B2 %}%
		%<-% %%.A
	)
%-|%


:MAIN_TEST2
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% MAIN TEST %}% %->% %%.T
		%<-% %%.T
	)
%-|%

:MAIN_TEST3
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% MAIN TEST2 %->% %%.T
		%<-% %%.T
	)
%-|%