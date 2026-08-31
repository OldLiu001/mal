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


rem no-main-invoke


:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Prompt=user> "
	)
:MAIN_Main
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Input=(+ 1 2)"
		echo R0
		%{% MAIN REP %%.Input %}%
		echo R1
	)
%-|%

:MAIN_Read Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Str=!%~1!"
		%{% READER ReadString "!%%.Str!" %}% %->% %%.Mal
		%?% %-|%
		%<-% %%.Mal
	)
%-|%

:MAIN_Eval Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%<-% %%.Mal
	)
%-|%

:MAIN_Print Mal -> Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Mal=!%~1!"
		%{% PRINTER PrintMalType "%%.Mal" %}% %->% %%.StrMal
		%?% (
			%-|%
		)
		%{% STR GetStr %%.StrMal %}% %->% %%.Result
		%?% (
			%-|%
		)
		%{% IO WriteEncLine %%.Result %}%
		%<-% %%.Result
	)
%-|%

:MAIN_REP Mal
	for %%. in (_L[!_G.LEVEL!].) do (
		echo REP_ENTER L=!_G.LEVEL! A1=%~1
		set "%%.Str=!%~1!"
		echo REP_STR=!%%.Str!
		%{% MAIN Read "%%.Str" %}% %->% %%.Mal
		%?% (
			%-|%
		)
		%{% MAIN Eval %%.Mal %}% %->% %%.Mal2
		%?% (
			%-|%
		)
		%{% MAIN Print %%.Mal2 %}%
	)
%-|%
