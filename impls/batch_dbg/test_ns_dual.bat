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
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)

%{% MAIN Main %}%
%-|%

:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		rem Test mode 1: pass NS var name directly
		%{n% %%.NS %}
		%{s% %%.NS Type Reader %}
		%{s% %%.NS TokenCount 5 %}
		%{s% %%.NS TokenPtr 1 %}

		echo NS=[!%%.NS!]

		rem Mode 1: pass var name (no ! expansion)
		%{g% %%.NS Type %%.T %}
		echo Type=[!%%.T!]

		%{g% %%.NS TokenCount %%.TC %}
		echo TokenCount=[!%%.TC!]

		%{g% %%.NS TokenPtr %%.TP %}
		echo TokenPtr=[!%%.TP!]

		rem Mode 2: pass NS ID (with ! expansion)
		%{g% "!%%.NS!" Type %%.T2 %}
		echo Type2=[!%%.T2!]

		%{g% "!%%.NS!" TokenCount %%.TC2 %}
		echo TokenCount2=[!%%.TC2!]

		rem Test HasField both modes
		%{% NSUTIL HasField %%.NS Type %}% %->% %%.HF1
		echo HasField_Mode1=[!%%.HF1!]

		%{% NSUTIL HasField "!%%.NS!" Type %}% %->% %%.HF2
		echo HasField_Mode2=[!%%.HF2!]

		rem Test IsValidNS both modes
		%{% NSUTIL IsValidNS %%.NS %}% %->% %%.IV1
		echo IsValidNS_Mode1=[!%%.IV1!]

		%{% NSUTIL IsValidNS "!%%.NS!" %}% %->% %%.IV2
		echo IsValidNS_Mode2=[!%%.IV2!]
	)
%-|%
